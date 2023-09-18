#ifndef SDFCOMMONDEF_HLSL
#define SDFCOMMONDEF_HLSL

#define Fast_MAXSDFTraceCount 256
#define Fast_SDFTraceThre 0.001

#include "../Transform/TransformCommonDef.hlsl"

//https://www.shadertoy.com/view/4sSSW3
//http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
//by my personal verify,sometimes it works,sometimes not very useful.
void basis_unstable(in float3 n, out float3 f, out float3 r)
{
	if (n.z < -0.999999)
	{
		f = float3(0, -1, 0);
		r = float3(-1, 0, 0);
	}
	else
	{
		float a = 1. / (1. + n.z);
		float b = -n.x * n.y * a;
		f = float3(1. - n.x * n.x * a, b, -n.x);
		r = float3(b, 1. - n.y * n.y * a, -n.y);
	}
}

//https://iquilezles.org/articles/smin/
float smin(float a, float b, float k = 0.1)
{
	float h = clamp(0.5 + 0.5*(b - a) / k, 0.0, 1.0);
	return lerp(b, a, h) - k * h*(1.0 - h);
}

float SDFSphere(float2 p, float2 center, float radius)
{
	return length(p - center) - radius;
}

float SDFSphere(float3 p, float3 center, float radius)
{
	return length(p - center) - radius;
}

float3 SDFSphereNormal(float3 p, float3 center)
{
	return normalize(p - center);
}

float SDFBox(float2 p, float2 center, float2 bound)
{
	float2 q = abs(p - center) - bound;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float SDFBox(float3 p, float3 center, float3 bound)
{
	//return SDFSphere(p, center, 1);
	float3 q = abs(p - center) - bound;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float SDFBox(float3 p, float3 center, float3 bound, float3 rotEuler)
{
	p = p - center;
	p = InvRotByEuler(p, rotEuler);
	float3 q = abs(p) - bound;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float SDFBoxByUVW(float3 p, float3 u, float3 v, float3 w, float3 center, float3 bound)
{
	p = p - center;
	float3 lp;
	lp.x = dot(p, u);
	lp.y = dot(p, v);
	lp.z = dot(p, w);
	return SDFBox(lp, float3(0, 0, 0), bound);
}

float SDFShearXBoxTransform(float3 p, float3 bound,
	float shy, float shz,
	float3 center, float3 rotEuler = 0, float3 scale = 1)
{
	p = WorldToLocal(p, center, rotEuler, scale);
	p = ShearZ(p, -shy, -shz);
	float3 q = abs(p) - bound;
	float re = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
	//!!! losszyScale use scale.x
	re *= scale.x;
	if (NearZero(shz) && NearZero(shy))
	{
		return re;
	}
	else if (NearZero(shz))
	{
		float tanY = abs(shy);
		return re * sin(atan(tanY));
	}
	else if (NearZero(shy))
	{
		float tanZ = abs(shz);
		return re * sin(atan(tanZ));
	}
	else
	{
		float tanY = abs(shy > 0 ? (1 / shz) : (shy));
		float tanZ = abs(shz > 0 ? (1 / shz) : (shz));
		return re * sin(atan(tanZ)) * sin(atan(tanY));
	}
	return re;
}

float SDFShearZBoxTransform(float3 p, float3 bound,
	float shx, float shy,
	float3 center, float3 rotEuler = 0, float3 scale = 1)
{
	//return SDFSphere(p, center, 1);
	p = WorldToLocal(p, center, rotEuler, scale);
	p = ShearZ(p, -shx, -shy);
	float3 q = abs(p) - bound;
	float re = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
	//!!! losszyScale use scale.x
	re *= scale.x;
	if (NearZero(shx) && NearZero(shy))
	{
		return re;
	}
	else if (NearZero(shy))
	{
		float tanX = abs(shx);
		return re * sin(atan(tanX));
	}
	else if (NearZero(shx))
	{
		float tanY = abs(shy);
		return re * sin(atan(tanY));
	}
	else
	{
		float tanX = abs(shx > 0 ? (1 / shy) : (shx));
		float tanY = abs(shy > 0 ? (1 / shy) : (shy));
		return re * sin(atan(tanY)) * sin(atan(tanX));
	}
}

float SDFShearXSphere(float3 p, float3 center, float radius,
	float shy, float shz)
{
	p = p - center;
	p = ShearX(p, -shy, -shz);
	float re = length(p) - radius;
	if (NearZero(shz) && NearZero(shy))
	{
		return re;
	}
	else if (NearZero(shz))
	{
		float tanY = abs(shy > 0 ? (1 / shz) : (shy));
		return re * sin(atan(tanY));
	}
	else if (NearZero(shy))
	{
		float tanZ = abs(shz > 0 ? (1 / shz) : (shz));
		return re * sin(atan(tanZ));
	}
	else
	{
		float tanY = abs(shy > 0 ? (1 / shz) : (shy));
		float tanZ = abs(shz > 0 ? (1 / shz) : (shz));
		return re * sin(atan(tanZ)) * sin(atan(tanY));
	}
}

void FastSDFTraceSphere(Ray ray, out HitInfo info
	, float3 center, float radius)
{
	Init(info);

	int traceCount = 0;
	while (traceCount <= Fast_MAXSDFTraceCount)
	{
		//get sdf at now pos
		float sdf = SDFSphere(ray.pos, center, radius);

		if (sdf <= Fast_SDFTraceThre)
		{
			info.bHit = true;
			//!!!
			info.obj = 0;
			info.N = SDFSphereNormal(ray.pos, center);
			info.P = ray.pos;
			break;
		}
		ray.pos += sdf * ray.dir;
		traceCount++;
	}
}

float SDFXCylinder(float3 p, float r)
{
	p.x = 0;
	return length(p) - r;
}

float3 SDFXCylinderNormal(float3 p)
{
	p.x = 0;
	return normalize(p);
}

float SDFXAxis(float3 p, float r)
{
	if (abs(p.z) > r)
	{
		p.x = 0;
		return min(
			length(p - float3(0, 0, r)), 
			length(p - float3(0, 0, -r))
		);
	}
	else
	{
		return abs(p.y);
	}
}

float3 SDFXAxisNormal(float3 p)
{
	return p.y > 0 ? float3(0, 1, 0) : float3(0, -1, 0);
}

float SDFTriangle2D(float2 p, float2 A, float2 B, float2 C)
{
	float2 AB = B - A;
	float2 BC = C - B;
	float2 CA = A - C;
	float2 ap = p - A;
	float2 bp = p - B;
	float2 cp = p - C;
	float lenAB = length(AB);
	float lenBC = length(BC);
	float lenCA = length(CA);

	float k1 = dot(ap, AB) / len2(lenAB);
	float k2 = dot(bp, BC) / len2(lenBC);
	float k3 = dot(cp, CA) / len2(lenCA);

	float c1 = cross2D(ap, AB);
	float c2 = cross2D(bp, BC);
	float c3 = cross2D(cp, CA);

	float lenap = length(ap);
	float lenbp = length(bp);
	float lencp = length(cp);

	if (Is01(k1) && c1 > 0.0f)
	{
		return sqrt(len2(lenap) - len2(k1*lenAB));
	}
	if (Is01(k2) && c2 > 0.0f)
	{
		return sqrt(len2(lenbp) - len2(k2*lenBC));
	}
	if (Is01(k3) && c3 > 0.0f)
	{
		return sqrt(len2(lencp) - len2(k3*lenCA));
	}

	if (c1 < 0.0f&&c2 < 0.0f&&c3 < 0.0f)
	{
		return 0.0f;
	}

	//return 0.0f;
	return min(min(lenap, lenbp), lencp);

}
float3 SDFTube(float3 q, float h, float tubeR, float tubeThick)
{
	float r = length(q.xz);
	float dTube = abs(r - tubeR) - tubeThick;
	return max(dTube, abs(q.y - h * 0.5) - h * 0.5);
}

float SDFCylinder(float3 p, float3 a, float3 b, float r)
{
	float3  ba = b - a;
	float3  pa = p - a;
	float ba2 = dot(ba, ba);
	float paba = dot(pa, ba);
	float x = length(pa*ba2 - ba * paba) - r * ba2;
	float y = abs(paba - ba2 * 0.5) - ba2 * 0.5;
	float x2 = x * x;
	float y2 = y * y*ba2;

	float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));

	return sign(d)*sqrt(abs(d)) / ba2;
}

float SDFCircleSlice(float3 q, float r, float hBound)
{
	float3 a = float3(0, -hBound, 0);
	float3 b = float3(0, hBound, 0);
	return SDFCylinder(q, a, b, r);
}

//https://www.shadertoy.com/view/7dlGRf
float SDFParallelogram(in float2 p, float wi, float he, float sk)
{
	float2  e = float2(sk, he);
	float e2 = sk * sk + he * he;

	p = (p.y < 0.0) ? -p : p;
	// horizontal edge
	float2  w = p - e; w.x -= clamp(w.x, -wi, wi);
	float2  d = float2(dot(w, w), -w.y);
	// vertical edge
	float s = p.x*e.y - p.y*e.x;
	p = (s < 0.0) ? -p : p;
	float2  v = p - float2(wi, 0); v -= e * clamp(dot(v, e) / e2, -1.0, 1.0);
	d = min(d, float2(dot(v, v), wi*he - abs(s)));
	return sqrt(d.x)*sign(-d.y);
}

// https://www.shadertoy.com/view/Md2BWW
float UDFQuad(in float3 p, in float3 v1, in float3 v2, in float3 v3, in float3 v4)
{
#if 1
	// handle ill formed quads
	if (dot(cross(v2 - v1, v4 - v1), cross(v4 - v3, v2 - v3)) < 0.0)
	{
		float3 tmp = v3;
		v3 = v4;
		v4 = tmp;
	}
#endif


	float3 v21 = v2 - v1; float3 p1 = p - v1;
	float3 v32 = v3 - v2; float3 p2 = p - v2;
	float3 v43 = v4 - v3; float3 p3 = p - v3;
	float3 v14 = v1 - v4; float3 p4 = p - v4;
	float3 nor = cross(v21, v14);

	return sqrt((sign(dot(cross(v21, nor), p1)) +
		sign(dot(cross(v32, nor), p2)) +
		sign(dot(cross(v43, nor), p3)) +
		sign(dot(cross(v14, nor), p4)) < 3.0)
		?
		min(min(dot2(v21*clamp(dot(v21, p1) / dot2(v21), 0.0, 1.0) - p1),
			dot2(v32*clamp(dot(v32, p2) / dot2(v32), 0.0, 1.0) - p2)),
			min(dot2(v43*clamp(dot(v43, p3) / dot2(v43), 0.0, 1.0) - p3),
				dot2(v14*clamp(dot(v14, p4) / dot2(v14), 0.0, 1.0) - p4)))
		:
		dot(nor, p1)*dot(nor, p1) / dot2(nor));
}

float UDFQuad2D(in float3 p, in float3 v1, in float3 v2, in float3 v3, in float3 v4)
{
	return UDFQuad(
		float3(p.x,0,p.z),
		float3(v1.x, 0, v1.z),
		float3(v2.x, 0, v2.z),
		float3(v3.x, 0, v3.z),
		float3(v4.x, 0, v4.z)
		);
}

float3 FixBound01(float3 p, float thre = 0)
{
	if (p.x < 0) { p.x = 0 + thre; }
	if (p.x > 1) { p.x = 1 - thre; }
	if (p.y < 0) { p.y = 0 + thre; }
	if (p.y > 1) { p.y = 1 - thre; }
	if (p.x < 0) { p.z = 0 + thre; }
	if (p.x > 1) { p.z = 1 - thre; }
	return p;
}

//??? only support Cube SDF_Tex3D for now
float SDFTex3D(float3 p, float3 center, float3 bound, float3 rotEuler, Texture3D<float> SDFTex3D, float traceThre, float offset = 0)
{
	float3 q = p - center;
	q = InvRotByEuler(q, rotEuler);
	float d = MAXFLOAT;
	if (gtor(abs(q), bound))
	{
		//not hit,than the sdf is sdfBox
		d = SDFBox(q, 0, bound) + traceThre * 2;

		//!Take scale.x to restore actual sdf
		float scale = bound.x / 0.5;
		//normalize to [0-1]
		q = q / scale + 0.5;
		q = FixBound01(q,0.01);
		float d2 = offset + SDFTex3D.SampleLevel(common_linear_clamp_sampler, q, 0).r;
		//restore sdf
		d2 *= scale;

		d += d2;
	}
	else
	{
		//!Take scale.x to restore actual sdf
		float scale = bound.x / 0.5;
		//normalize to [0-1]
		q = q/ scale +0.5;
		d = offset + SDFTex3D.SampleLevel(common_linear_clamp_sampler, q, 0).r;
		//restore sdf
		d *= scale;
	}
	return d;
}

float SDFSlice(float3 p, float3 center, float3 rotEuler, float3 size, Texture2D<float> SliceTex, float hBound, float traceThre, float offset2D, float offset)
{
	float3 q = WorldToLocal(p, center, rotEuler, size);
	float dh = abs(q.y) - hBound;
	dh = dh > 0 ? dh : 0;
	float scale = size.x;
	dh *= scale;

	float d = MAXFLOAT;
	float d2d = MAXFLOAT;
	float2 picBound = float2(0.5, 0.5) * scale;
	float2 p2d = q.xz * scale;
	if (gtor(abs(p2d), picBound))
	{
		d2d = SDFBox(p2d, 0, picBound) + traceThre * 2;
		d = sqrt(d2d * d2d + dh * dh);

		//float2 uv = p2d / picBound;
		//uv = (uv + 1) * 0.5;
		//uint2 picSize = GetSize(SliceTex);
		//float sdfFromPic = SliceTex.SampleLevel(common_linear_repeat_sampler, uv, 0).r;
		//sdfFromPic /= picSize.x * 0.5 * sqrt(2) * scale;
		//sdfFromPic *= picBound.x;
		//d2d = sdfFromPic;
		//d2d += offset2D;
		//d2d = max(d2d, 0);
		//d = sqrt(d2d * d2d + dh * dh);
		//d += offset;
		//
		//d += d1;
	}
	else
	{
		float2 uv = p2d / picBound;
		uv = (uv + 1) * 0.5;
		uint2 picSize = GetSize(SliceTex);
		float sdfFromPic = SliceTex.SampleLevel(common_linear_repeat_sampler, uv, 0).r;
		sdfFromPic /= picSize.x * 0.5 * sqrt(2) * scale;
		sdfFromPic *= picBound.x;
		d2d = sdfFromPic;
		d2d += offset2D;
		d2d = max(d2d, 0);
		d = sqrt(d2d * d2d + dh * dh);
		d += offset;
	}
	return d;
}

float SDFSlice_Sub(float3 p, float3 center, float3 rotEuler, float3 size, Texture2D<float> SliceTex, float hBound, float traceThre, float offset2D, float offset, float4 subInfo)
{
	float3 q = WorldToLocal(p, center, rotEuler, size);
	float dh = abs(q.y) - hBound;
	dh = dh > 0 ? dh : 0;
	float scale = size.x;
	dh *= scale;

	float d = MAXFLOAT;
	float d2d = MAXFLOAT;
	float2 picBound = float2(0.5, 0.5) * scale;
	float2 p2d = q.xz * scale;
	if (gtor(abs(p2d), picBound))
	{
		d2d = SDFBox(p2d, 0, picBound) + traceThre * 2;
		d = sqrt(d2d * d2d + dh * dh);
	}
	else
	{
		float2 uv = p2d / picBound;
		uv = (uv + 1) * 0.5;
		uint2 picSize = GetSize(SliceTex);
		uv = GetSubUV(uv, subInfo);
		float sdfFromPic = SliceTex.SampleLevel(common_linear_repeat_sampler, uv, 0).r;
		sdfFromPic /= picSize.x * 0.5 * sqrt(2) * scale;
		sdfFromPic *= picBound.x;
		d2d = sdfFromPic;
		d2d += offset2D;
		d2d = max(d2d, 0);
		d = sqrt(d2d * d2d + dh * dh);
		d += offset;
	}
	return d;
}

float SDFHeightSlice(float3 q, float d2d, float hBound)
{
	d2d = max(d2d, 0);
	float dh = abs(q.y) - hBound;
	dh = dh > 0 ? dh : 0;
	return sqrt(d2d*d2d + dh * dh);
}

float3 SDFTexNorm3D(float3 p, float3 center, float3 bound, Texture3D<float3> SDFNorm3D)
{
	float3 q = p - center;
	if (gtor(abs(q), bound))
	{
		return 0;
	}
	q /= (bound.x/0.5);
	return SDFNorm3D.SampleLevel(common_linear_clamp_sampler, q + 0.5, 0).rgb;
}

//---Grid Cell-------------------------------------------------------
float3 GetGridCenter_DownMode(float3 p, float3 grid, float3 offset = 0)
{
	p -= offset;
	float dis = grid.y;
	float m = round(p.y / dis);
	float centerY = m * dis;

	float2 grid2 = grid.xz;
	float2 m1 = floor(p.xz / grid2);
	float2 c = grid2 * (m1 + 0.5);
	return float3(c.x, centerY, c.y) + offset;
}

float3 GetGridCenterWithID_DownMode(float3 p, float3 grid, out float3 id, float3 offset = 0)
{
	p -= offset;
	float dis = grid.y;
	float m = round(p.y / dis);
	float centerY = m * dis;

	float2 grid2 = grid.xz;
	float2 m1 = floor(p.xz / grid2);
	float2 c = grid2 * (m1 + 0.5);

	id = float3(m1.x, m, m1.y);
	return float3(c.x, centerY, c.y) + offset;
}

float3 GetGridCenter_MidMode(float3 p, float3 grid, float3 offset = 0)
{
	float3 m = floor(p / grid);
	return grid * (m + float3(0.5, 0, 0.5)) + offset;
}

float3 GetGridCenterWithID_MidMode(float3 p, float3 grid, out float3 id, float3 offset = 0)
{
	id = floor(p / grid);
	return grid * (id + float3(0.5, 0, 0.5)) + offset;
}

float3 GetCellCenter_MidMode(float3 p, float3 grid, float3 offset = 0)
{
	float3 m = floor(p / grid);
	return grid * (m + float3(0.5, 0.5, 0.5)) + offset;
}

float3 GetCellCenterWithID_MidMode(float3 p, float3 grid, out float3 id, float3 offset = 0)
{
	id = floor(p / grid);
	return grid * (id + float3(0.5, 0.5, 0.5)) + offset;
}
//___Grid Cell_____________________________________________________________

//---ShowInt-------------------------------------------------------
float DigSeg(float2 q)
{
	return step(abs(q.x), 0.12) * step(abs(q.y), 0.6);
}

#define DSG(q) k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q)

float ShowDig(float2 q, int iv)
{
	float d;
	int k, kk;
	float2 vp = float2 (0.5, 0.5), vm = float2 (-0.5, 0.5), vo = float2 (1., 0.);
	if (iv == -1) k = 8;
	else if (iv < 2) k = (iv == 0) ? 119 : 36;
	else if (iv < 4) k = (iv == 2) ? 93 : 109;
	else if (iv < 6) k = (iv == 4) ? 46 : 107;
	else if (iv < 8) k = (iv == 6) ? 122 : 37;
	else             k = (iv == 8) ? 127 : 47;
	q = (q - 0.5);
	d = 0.;
	kk = k;
	DSG(q.yx - vo);  DSG(q.xy - vp);  DSG(q.xy - vm);  DSG(q.yx);
	DSG(q.xy + vm);  DSG(q.xy + vp);  DSG(q.yx + vo);
	return d;
}

float ShowInt(float2 q, int iv, int maxLen = 4)
{
	q.x *= -1;
	int base = 10;
	int tnum = iv;
	int resi;
	float re = 0;
	float2 offset = float2(2, 0);
	int i = 0;
	if (iv < 0)
	{
		tnum = abs(tnum);
	}
	for (; i < maxLen; i++)
	{
		resi = tnum % base;
		re += ShowDig(q - offset * i, resi);
		tnum -= resi;
		tnum /= base;
		if (tnum == 0)
		{
			break;
		}
	}
	if (iv < 0)
	{
		re += ShowDig(q - offset * (i + 1), -1);
	}
	return re;
}
//___ShowInt___________________________________________

#endif
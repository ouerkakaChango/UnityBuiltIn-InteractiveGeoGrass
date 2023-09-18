#ifndef COMMONDEF_HLSL
#define COMMONDEF_HLSL

#define PI 3.14159
#define TWOPI 6.2831853
#define MAXFLOAT 3.402823e38

#include "UnityCommonDef.hlsl"

struct Ray
{
	float3 pos;
	float3 dir;
};

struct Vertex
{
	float3 p;
	float3 n;
	float2 uv;
};

struct HitInfo
{
	int bHit;
	int obj;
	float3 N;
	float3 P;
};

struct TraceInfo
{
	int traceCount;
	float traceSum;
	float lastTrace;
};

struct VertHitInfo
{
	int bHit;
	int obj;
	float3 n;
	float3 p;
	float2 uv;
};

struct CastInfo
{
	bool bHit;
	float dis;
};

struct Grid
{
	float3 startPos;
	float3 unitCount;
	float3 unit;
};

void Init(out HitInfo re)
{
	re.bHit = 0;
	re.obj = -1;
	re.N = 0;
	re.P = 0;
}

void Init(out TraceInfo re)
{
	re.traceCount = 0;
	re.traceSum = 0;
	re.lastTrace = MAXFLOAT;
}

void Init(out VertHitInfo re)
{
	re.bHit = 0;
	re.obj = -1;
	re.n = 0;
	re.p = 0;
	re.uv = 0;
}

void Init(out CastInfo re)
{
	re.bHit = false;
	re.dis = 0;
}

void Assgin(out HitInfo re, HitInfo hit)
{
	re.bHit = hit.bHit;
	re.obj = hit.obj;
	re.N = hit.N;
	re.P = hit.P;
}

void Update(inout TraceInfo traceInfo, float sdf)
{
	traceInfo.traceCount += 1;
	traceInfo.lastTrace = sdf;
}

bool NearZero(float x)
{
	return abs(x) < 0.000001f;
}

bool gt(float2 a, float2 b)
{
	return a.x > b.x && a.y > b.y;
}

bool gtor(float2 a, float2 b)
{
	return a.x > b.x || a.y > b.y;
}

bool gtor(float3 a, float3 b)
{
	return a.x > b.x || a.y > b.y || a.z > b.z;
}

bool gt(float3 a, float3 b)
{
	return a.x > b.x && a.y > b.y && a.z > b.z;
}

bool lt(float2 a, float2 b)
{
	return a.x < b.x && a.y < b.y;
}

bool lt(float3 a, float3 b)
{
	return a.x < b.x && a.y < b.y && a.z < b.z;
}

bool eq(int2 a, int2 b)
{
	return a.x == b.x && a.y == b.y;
}

bool eq(uint2 a, uint2 b)
{
	return a.x == b.x && a.y == b.y;
}

bool equal(float a, float b, float tolerance = 0.000001f)
{
	return abs(a - b) < tolerance;
}

bool equal(float3 a, float3 b, float tolerance = 0.000001f)
{
	return equal(a.x, b.x, tolerance) &&
		equal(a.y, b.y, tolerance) &&
		equal(a.z, b.z, tolerance);
}

float smooth3(float t)
{
	return t * t * (3.0 - 2.0 * t);
}

float3 smooth3(float3 t)
{
	return t * t * (3.0 - 2.0 * t);
}

//https://stackoverflow.com/questions/28740544/inverted-smoothstep
float invSmooth3(float x) {
	return x + (x - (x * x * (3.0f - 2.0f * x)));

	//if (x <= 0)return 0;
	//if (x >= 1)return 1;
	//return 0.5f - sin(asin(1 - 2 * x) / 3);
}

inline bool Is01(float x)
{
	return x > 0 && x < 1;
}

inline bool Is01(float2 v)
{
	return v.x >= 0 && v.x <= 1 &&
		v.y >= 0 && v.y <= 1;
}

float dot2(float2 x)
{
	return dot(x, x);
}

float dot2(float3 x)
{
	return dot(x, x);
}

float len2(float x)
{
	return x * x;
}
float cross2D(float2 v1, float2 v2)
{
	return v1.x*v2.y - v1.y*v2.x;
}

float addv(float2 a) { return a.x + a.y; }

//###############################################################

int GetTreeDepth(int inx,int maxDepth)
{
	//depht = 2,  >=2^2-1, <=2^3-2
	for (int i = 0; i <= maxDepth; i++)
	{
		int up = (int)pow(2, i + 1) - 2;
		if(inx< up)
		{
			return i;
		}
	}
	return -1;
}

void GetMaxAxisInfo(float3 vec, out int axisInx, out int axisSign)
{
	axisInx = -1; axisSign = 0;
	float3 avec = abs(vec);
	if (avec.x >= avec.y&&avec.x >= avec.z)
	{
		axisInx = 0;
		axisSign = sign(vec.x);
	}
	else if (avec.y >= avec.x&&avec.y >= avec.z)
	{
		axisInx = 1;
		axisSign = sign(vec.y);
	}
	else if (avec.z >= avec.x&&avec.z >= avec.y)
	{
		axisInx = 2;
		axisSign = sign(vec.z);
	}
	if (axisSign == 0)
	{
		axisSign = 1;
	}
}

//###############################################################

float Time01(float frequency=1.0f,float phi = 0.0f)
{
	return 0.5*(sin(frequency * _Time.y+phi) + 1);
}

//####################################################################

SamplerState common_point_repeat_sampler;
SamplerState common_linear_repeat_sampler;
SamplerState common_trilinear_repeat_sampler;
SamplerState common_point_clamp_sampler;
SamplerState common_linear_clamp_sampler;
SamplerState common_trilinear_clamp_sampler;

float2 GetUV(RWTexture2D<float4> dst, uint3 id)
{
	uint dstW, dstH; 
	dst.GetDimensions(dstW, dstH);
	return float2(
		((float)id.x) / dstW,
		((float)id.y) / dstH);
}

float2 GetUV(RWTexture2D<half4> dst, uint3 id)
{
	uint dstW, dstH;
	dst.GetDimensions(dstW, dstH);
	return float2(
		((float)id.x) / dstW,
		((float)id.y) / dstH);
}

float2 GetUV(Texture2D<float4> dst, uint3 id)
{
	uint dstW, dstH;
	dst.GetDimensions(dstW, dstH);
	return float2(
		((float)id.x) / dstW,
		((float)id.y) / dstH);
}

uint2 GetSize(RWTexture2D<float4> dst)
{
	uint2 size;
	dst.GetDimensions(size.x, size.y);
	return size;
}

uint2 GetSize(Texture2D<float4> dst)
{
	uint2 size;
	dst.GetDimensions(size.x, size.y);
	return size;
}

uint2 GetSize(Texture2D<float3> dst)
{
	uint2 size;
	dst.GetDimensions(size.x, size.y);
	return size;
}

uint2 GetSize(Texture2D<float2> dst)
{
	uint2 size;
	dst.GetDimensions(size.x, size.y);
	return size;
}

uint2 GetSize(Texture2D<float> dst)
{
	uint2 size;
	dst.GetDimensions(size.x, size.y);
	return size;
}

int GetSize(StructuredBuffer<float2> arr)
{
	uint numStructs, stride;
	arr.GetDimensions(numStructs, stride);
	return (int)numStructs;
}



uint2 TexSafePos(float2 pos, uint2 size)
{
	if (size.x < (uint)1 || size.y < (uint)1)
	{
		return uint2(0,0);
	}

	float2 re = pos;
	if (re.x < 0)
	{
		re.x = 0;
	}
	else if (re.x >= (float)size.x)
	{
		re.x = (float)size.x - 1;
	}
	
	if (re.y < 0)
	{
		re.y = 0;
	}
	else if (re.y > (float)size.y)
	{
		re.y = (float)size.y - 1;
	}
	return (uint2)re;
}

float BilinearR(Texture2D tex, float2 floorPos, float2 fracPart)
{
	uint2 size = GetSize(tex);
	//float x00 = tex[floorPos].r;
	//float x10 = tex[TexSafePos(floorPos + int2(1, 0), size)].r;
	//float x01 = tex[TexSafePos(floorPos + int2(0, 1), size)].r;
	//float x11 = tex[TexSafePos(floorPos + int2(1, 1), size)].r;
	float x00 = tex.SampleLevel(common_point_repeat_sampler, floorPos/size, 0).x;
	float x10 = tex.SampleLevel(common_point_repeat_sampler, TexSafePos(floorPos + int2(1, 0), size) / (float2)size, 0).x;
	float x01 = tex.SampleLevel(common_point_repeat_sampler, TexSafePos(floorPos + int2(0, 1), size) / (float2)size, 0).x;
	float x11 = tex.SampleLevel(common_point_repeat_sampler, TexSafePos(floorPos + int2(1, 1), size) / (float2)size, 0).x;
	float x0 = lerp(x00, x10, fracPart.x);
	float x1 = lerp(x01, x11, fracPart.x);
	return lerp(x0, x1, fracPart.y);
}

float3 BilinearRGB(Texture2D<float3> tex, float2 uv)
{
	uint2 size = GetSize(tex);
	float2 realPos = uv * size;
	int2 floorPos = floor(realPos);
	float2 fracPart = saturate(realPos - floorPos);

	int dis = 1;
	float3 x00 = tex[floorPos];
	float3 x10 = tex[TexSafePos(floorPos + int2(dis, 0), size)];
	float3 x01 = tex[TexSafePos(floorPos + int2(0, dis), size)];
	float3 x11 = tex[TexSafePos(floorPos + int2(dis, dis), size)];
	float3 x0 = lerp(x00, x10, fracPart.x);
	float3 x1 = lerp(x01, x11, fracPart.x);

	return lerp(x0, x1, fracPart.y);
}

float SampleR(in Texture2D tex, float2 uv, int mip = 0)
{
	return tex.SampleLevel(common_linear_repeat_sampler, uv, mip).r;
}

float SampleR(in Texture2D<float> tex, float2 uv, int mip = 0)
{
	return tex.SampleLevel(common_linear_repeat_sampler, uv, mip).r;
}

float3 SampleRGB(in Texture2D tex, float2 uv)
{
	return tex.SampleLevel(common_linear_repeat_sampler, uv, 0).rgb;
}

float3 SampleRGB(in Texture2D<float3> tex, float2 uv, int mip=0)
{
	return tex.SampleLevel(common_linear_repeat_sampler, uv, mip).rgb;
}

float3 GetRGB(in Texture2D<float3> tex, float2 uv)
{
	return tex.SampleLevel(common_point_repeat_sampler, uv, 0).rgb;
}

float3 GetRGB(in Texture2D<float4> tex, float2 uv)
{
	return tex.SampleLevel(common_point_repeat_sampler, uv, 0).rgb;
}

float4 SampleRGBA(in Texture2D<float4> tex, float2 uv)
{
	return tex.SampleLevel(common_linear_repeat_sampler, uv, 0).rgba;
}
//###############################################################################
//https://www.shadertoy.com/view/wt23Rt
float3 RGBToHSV(float3 c) {
	float4 K = float4(0., -1. / 3., 2. / 3., -1.),
		p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g)),
		q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y),
		e = 1e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.*d + e)), d / (q.x + e), q.x);
}

//https://www.shadertoy.com/view/MsS3Wc
float3 HSVToRGB_iq(in float3 c)
{
	float3 rgb = clamp(abs(fmod(c.x*6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	rgb = rgb * rgb*(3.0 - 2.0*rgb); // cubic smoothing	
	return c.z * lerp(float3(1,1,1), rgb, c.y);
}

//https://www.shadertoy.com/view/wt23Rt
float3 HSVToRGB(float3 c) {
	float4 K = float4(1., 2. / 3., 1. / 3., 3.);
	return c.z*lerp(K.xxx, saturate(abs(frac(c.x + K.xyz)*6. - K.w) - K.x), c.y);
}

//https://www.shadertoy.com/view/4dcSRN
float3 RGBToYCoCg(float3 rgb)
{
	float tmp = 0.5*(rgb.r + rgb.b);
	float y = rgb.g + tmp;
	float Cg = rgb.g - tmp;
	float Co = rgb.r - rgb.b;
	return float3(y, Co, Cg) * 0.5;
}


float3 YCoCgToRGB(float3 ycocg)
{
	float2 br = float2(-ycocg.y, ycocg.y) - ycocg.z;
	return ycocg.x + float3(br.y, ycocg.z, br.x);
}

//###############################################################################

//glsl version mod,change from cg-language implementation --xc
float2 gmod(float2 a, float2 b)
{
	float2 c = frac(abs(a / b))*abs(b);
	return c;//(a < 0) ? -c : c;   /* if ( a < 0 ) c = 0-c */
}

//(edgeLow,edgeHigh,smoothRange,x)
//(0.1,0.9,0.02,x)
float SmoothBump(float lo, float hi, float w, float x)
{
	return (1. - smoothstep(hi - w, hi + w, x)) * smoothstep(lo - w, lo + w, x);
}

float2 GetSubUV(float2 uv, float4 subInfo)
{
	int edgeX = subInfo.x;
	int edgeY = subInfo.y;
	if (edgeX > 0 && edgeY > 0)
	{
		int subID = subInfo.z;
		int idx = subID % edgeX;
		int idy = (subID - idx) / edgeY;

		float2 cell = 1 / float2(edgeX, edgeY);
		float2 origin = float2(idx*cell.x, idy*cell.y);
		//localuv = (worlduv - origin) / cell;
		uv = uv * cell + origin;
	}
	return uv;
}

float FixNormal(float x, float y)
{
	return sqrt(1 - x * x - y * y);
}

float PntLightAtten(float3 pos, float3 lightPos)
{
	float d = length(pos - lightPos);
	return saturate(1 / (d*d));
	//return 1 / (1 + 0.01*d + 0.005*d*d);
}

float grey(float3 c)
{
	return c.r*0.3 + c.g*0.6 + c.b*0.1;
}
#endif
#ifndef TREANDFORMCOMMONDEF_HLSL
#define TREANDFORMCOMMONDEF_HLSL
#include "../CommonDef.hlsl"

//correct:z-x-y,inv:y-x-z
//Transform logic based on unity coordinate:x-right, y-up, z-in
float3 InvRotByEuler(float3 p, float3 eulerAngle)
{
	float a = eulerAngle.x / 180.0f * PI;
	float b = eulerAngle.y / 180.0f * PI;
	float c = eulerAngle.z / 180.0f * PI;
	float3x3 rotx = {
		1,0,0,
		0,cos(a),sin(a),
		0,-sin(a),cos(a)
	};

	float3x3 roty = {
		cos(b),0,-sin(b),
		0,1,0,
		sin(b),0,cos(b)
	};

	float3x3 rotz =
	{
		cos(c),sin(c),0,
		-sin(c),cos(c),0,
		0,0,1
	};

	p = mul(roty, p);
	p = mul(rotx, p);
	p = mul(rotz, p);
	return p;
}

float3 InvRotCenterByEuler(float3 p, float3 rotCenter, float3 rotEuler)
{
	float3 locP = p - rotCenter;
	locP = InvRotByEuler(locP, rotEuler);
	return locP + rotCenter;
}

float3 RotByEuler(float3 p, float3 eulerAngle)
{
	float a = eulerAngle.x / 180.0f * PI;
	float b = eulerAngle.y / 180.0f * PI;
	float c = eulerAngle.z / 180.0f * PI;
	float3x3 rotx = {
		1,0,0,
		0,cos(a),sin(a),
		0,-sin(a),cos(a)
	};

	float3x3 roty = {
		cos(b),0,-sin(b),
		0,1,0,
		sin(b),0,cos(b)
	};

	float3x3 rotz =
	{
		cos(c),sin(c),0,
		-sin(c),cos(c),0,
		0,0,1
	};

	p = mul(rotz, p);
	p = mul(rotx, p);
	p = mul(roty, p);
	return p;
}

float3 RotCenterByEuler(float3 p, float3 rotCenter, float3 rotEuler)
{
	float3 locP = p - rotCenter;
	locP = RotByEuler(locP, rotEuler);
	return locP + rotCenter;
}

float2 rotate(float2 p, float a)
{
	float c = cos(a), s = sin(a);
	float2x2 mat = { c,-s,s,c };
	return mul(mat, p);
}

//https://www.gatevidyalay.com/3d-shearing-in-computer-graphics-definition-examples/#:~:text=in%20Computer%20Graphics%2D-,In%20Computer%20graphics%2C,as%20well%20as%20Z%20direction.
float3 ShearX(float3 p, float shy, float shz)
{
	float3x3 m = {
		1,0,0,
		shy,1,0,
		shz,0,1
	};
	return mul(m, p);
}

float3 ShearZ(float3 p, float shx, float shy)
{
	float3x3 m = {
		1,0,shx,
		0,1,shy,
		0,0,1
	};
	return mul(m, p);
}

//###############################################

struct Transform
{
	float3 pos;
	float3 rotEuler;
	float3 scale;
};

void Init(out Transform trans)
{
	trans.pos = float3(0, 0, 0);
	trans.rotEuler = float3(0, 0, 0);
	trans.scale = float3(1, 1, 1);
}

float3 WorldToLocal(in Transform trans, float3 world)
{
	float3 p = world - trans.pos;
	p /= trans.scale;
	p = InvRotByEuler(p, trans.rotEuler);
	return p;
}

float3 WorldToLocal(float3 world, in float3 pos, in float3 rotEuler,in float3 scale)
{
	float3 p = world - pos;
	p /= scale;
	p = InvRotByEuler(p, rotEuler);
	return p;
}

float3 LocalToWorld(in Transform trans, float3 local)
{
	float3 p = RotByEuler(local, trans.rotEuler);
	p *= trans.scale;
	p += trans.pos;
	return p;
}

//local to world
float3 To3D(in Transform trans, float2 p2d)
{
	return LocalToWorld(trans, float3(p2d.x, 0, p2d.y));
}

//local to world
//assume dir has normalized
float3 DirTo3D(in Transform trans, float2 dir)
{
	float3 re = float3(dir.x, 0, dir.y);
	return InvRotByEuler(re, trans.rotEuler);
}

//############

struct Coord2D
{
	float3 origin;
	float3 T, B, N;
};

float3 WorldToLocal(in Coord2D coord, float3 p)
{
	float3 d = p - coord.origin;
	return float3(
		dot(d, coord.T),
		dot(d, coord.B),
		dot(d, coord.N)
		);
}

void ProjToCoord2D(out float2 p2d, out float projDis, float3 p, in Coord2D coord)
{
	float3 pLocal = WorldToLocal(coord, p);
	projDis = pLocal.z;
	p2d = pLocal.xy;
}
#endif
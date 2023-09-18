using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace TransformTool
{
    public static class TransformCommonDef
    {
        public static void SetLocalScaleY(this Transform trans, float sy)
        {
            Vector3 s = trans.localScale;
            s.y = sy;
            trans.localScale = s;
        }
    }
}
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class GrassRTHelper : MonoBehaviour
{
    public RTPlane rtPlane;
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(LateStart());
        if (rtPlane==null)
        {
            Debug.LogError("rtPlane wrong");
        }
    }

    IEnumerator LateStart()
    {
        yield return new WaitForFixedUpdate();
        //Your Function You Want to Call
        var render = GetComponent<Renderer>();
        var mat = render.material;
        mat.SetTexture("_MaskRT", rtPlane.rt1);
        Vector2 ori = VecXZ(rtPlane.transform.position) - 0.5f * rtPlane.size;
        
        Vector4 maskuv = new Vector4(ori.x, ori.y, rtPlane.size.x, rtPlane.size.y);
        mat.SetVector("_MaskUV", maskuv);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    Vector2 VecXZ(Vector3 pos)
    {
        return new Vector2(pos.x, pos.z);
    }
}

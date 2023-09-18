using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BaseRotater : MonoBehaviour
{
    public Vector3 dRotPerSec = new Vector3(0,90.0f,0);
    public bool bRotInEditor = true;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        bool bRot = true;

        bRot = (Application.isPlaying) || bRotInEditor;

        if (bRot)
        {
            var dR = dRotPerSec * Time.deltaTime;
            transform.eulerAngles += dR;
        }
    }
}

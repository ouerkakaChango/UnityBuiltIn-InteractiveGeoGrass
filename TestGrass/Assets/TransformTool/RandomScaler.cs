using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static TransformTool.TransformCommonDef;
public class RandomScaler : MonoBehaviour
{
    public bool ignoreTimeScale = true;
    public Vector2 range;
    public bool playOnStart = true;
    public float time_update = 0.1f;
    float t_update;

    bool doing = false;
    // Start is called before the first frame update
    void Start()
    {
        if(playOnStart)
        {
            DoAction();
        }
    }

    // Update is called once per frame
    void Update()
    {
        if(doing)
        {
            t_update += Time.deltaTime;
            float timescale = 1.0f;
            if(ignoreTimeScale)
            {
                timescale = Time.timeScale;
            }
            if(t_update>=time_update* timescale)
            {
                UpdateScaler();
                t_update = 0;
            }
        }
    }

    public void DoAction()
    {
        t_update = 0;
        doing = true;
    }

    void UpdateScaler()
    {
        transform.SetLocalScaleY (Random.Range(range.x, range.y));
    }
}

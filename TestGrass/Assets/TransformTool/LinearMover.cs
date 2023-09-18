using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LinearMover : MonoBehaviour
{
    public Vector3 direction = new Vector3(0, 0, 1);
    public float moveLength = 5.0f;
    public float speed = 5.0f;

    Vector3 startPos;
    float sum = 0.0f;
    // Start is called before the first frame update
    void Start()
    {
        startPos = transform.position;
    }

    void Update()
    {
        float dLen = Time.deltaTime * speed;
        sum += dLen;
        float k = LinearLoopFunc(sum, moveLength);
        transform.position = startPos + k * direction;
    }

    float LinearLoopFunc(float x,float a)
    {
        float fx = x % a;
        bool flag = (int)((x - fx) / a) % 2 == 0;
        if(flag)
        {
            return fx;
        }
        else
        {
            return a - fx;
        }
    }

}

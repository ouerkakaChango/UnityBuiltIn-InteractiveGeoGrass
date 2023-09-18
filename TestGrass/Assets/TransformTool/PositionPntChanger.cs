using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PositionPntChanger : MonoBehaviour
{
    public List<Vector3> positions = new List<Vector3>();
    [SerializeField]
    public int inx = 0;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void Record()
    {
        positions.Add(transform.position);
    }

    public void Change()
    {
        inx++;
      
        if (inx >= positions.Count)
        {
            inx = 0;
        }

        if (positions.Count > 0)
        {
            transform.position = positions[inx];
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(PositionPntChanger))]
public class PositionPntChangerEditor : Editor
{
    PositionPntChanger Target;
    void OnEnable()
    {
        Target = (PositionPntChanger)target;
    }

    //@@@
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Record"))
        {
            Target.Record();
        }

        if (GUILayout.Button("Change"))
        {
            //serializedObject.FindProperty("inx").intValue += 1;
            Target.Change();
            EditorUtility.SetDirty(Target);
        }
        serializedObject.ApplyModifiedProperties();
    }
}

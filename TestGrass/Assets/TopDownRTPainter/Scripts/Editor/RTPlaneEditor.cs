using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(RTPlane))]
public class RTPlaneEditor : Editor
{
    RTPlane Target;
    private void OnEnable()
    {
        Target = (RTPlane)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        //SerializedProperty weaponTime = serializedObject.FindProperty("weaponTime");
        //EditorGUILayout.PropertyField(weaponTime, new GUIContent("weaponTime"), true);

        //Target.weaponTime.up = EditorGUILayout.FloatField("weaponUp", Target.weaponTime.up);
        //var newcd = EditorGUILayout.FloatField("weaponCD", Target.weaponTime.cd);
        //if(newcd!=Target.weaponTime.cd)
        //{
        //    Target.weaponTime.cd = newcd;
        //}
        //Target.weaponTime.down = EditorGUILayout.FloatField("weaponDown", Target.weaponTime.down);

        if(Target.useDebugRenderer)
        {
            SerializedProperty weaponTime = serializedObject.FindProperty("debugRenderer");
            EditorGUILayout.PropertyField(weaponTime, new GUIContent("debugRenderer"), true);

        }

        serializedObject.ApplyModifiedProperties();
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum FPSDebugSetting
{
    Free,
    Target60,
    Target30,
}

public class FPSDebugger : MonoBehaviour
{
    public FPSDebugSetting fpsSetting = FPSDebugSetting.Free;
    int fps;

    GUIStyle style;
    private void Start()
    {
        style = new GUIStyle();
        style.fontSize = 40;
        style.normal.textColor = Color.red;

        if (fpsSetting == FPSDebugSetting.Target60)
        {
            Application.targetFrameRate = 60;
        }
        else if (fpsSetting == FPSDebugSetting.Target30)
        {
            Application.targetFrameRate = 30;
        }
        else if (fpsSetting == FPSDebugSetting.Free)
        {
            Application.targetFrameRate = -1;
        }
    }

    public void Update()
    {
        fps = (int)(1f / Time.unscaledDeltaTime);
    }

    //@@@
    private void OnGUI()
    {
        GUI.Label(new Rect(Screen.width / 2, Screen.height / 2, 300, 50), "FPS: " + fps, style);
    }
}

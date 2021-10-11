 using System;
 using UnityEngine;
 using UnityEngine.UI;
 
 // https://answers.unity.com/questions/46745/how-do-i-find-the-frames-per-second-of-my-game.html

     [RequireComponent(typeof (UnityEngine.UI.Text))]
     public class FPSDisplay : MonoBehaviour
     {
         const float fpsMeasurePeriod = 0.5f;
         private int m_FpsAccumulator = 0;
         private float m_FpsNextPeriod = 0;
         private int m_CurrentFps;
         const string display = "Lights: {1}, {0} FPS";
         private Text m_Text;
 
 
         private void Start()
         {
             m_FpsNextPeriod = Time.realtimeSinceStartup + fpsMeasurePeriod;
             m_Text = GetComponent<Text>();
         }
 
 
         private void Update()
         {
             // measure average frames per second
             m_FpsAccumulator++;
             if (Time.realtimeSinceStartup > m_FpsNextPeriod)
             {
                 m_CurrentFps = (int) (m_FpsAccumulator/fpsMeasurePeriod);
                 m_FpsAccumulator = 0;
                 m_FpsNextPeriod += fpsMeasurePeriod;
                 m_Text.text = string.Format(display, m_CurrentFps, (LightComponent.dynamicLights.Count + LightComponent.staticLights.Count));
                 
                 //Interestingly the below code shaved about 100 FPS off our framecount. 
                 //"Lights: " + (LightComponent.dynamicLights.Count + LightComponent.staticLights.Count) + " FPS: " + m_CurrentFps;
             }
         }
     }
 
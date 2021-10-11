using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif

[System.Serializable]
public struct RampStyle
{
    [SerializeField]
    public Texture2D Ramp;

    [SerializeField]
    public Texture2D Skybox;

    [SerializeField]
    public Color FogColour;
}

public class RenderPipe : MonoBehaviour
{
    [SerializeField]
    private Vector3 lightDirectionChoice = new Vector3(59,0,0);
    private Vector3 _currentLightDirection = new Vector3(-1,-1,-1);

    [SerializeField]
    private int rampChoice = 0;
    private int _currentRamp = -1;

    [SerializeField]
    private float fogFadeFactor = 0.20f;
    private float _currentFogFade = 0;

    [SerializeField]
    private RampStyle[] rampStyles;

    [SerializeField]
    private Shader depthNormalShader;

    [SerializeField]
    private Shader lightShader;

    private RenderTexture depthTexture;
    private RenderTexture normalTexture;
    private RenderTexture lightTexture;

    private Camera theCamera;
    [SerializeField]
    private Camera bufferCamera;

    // Init all our things...
    private void Awake()
    {
        // Create our lovely buffers...
        if(depthTexture == null)
        {
            depthTexture = new RenderTexture(Screen.width, Screen.height, 32, RenderTextureFormat.Depth);
            depthTexture.filterMode = FilterMode.Point;
            depthTexture.SetGlobalShaderProperty("_depthTexture");
        }

        if(normalTexture == null)
        {
            normalTexture = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            normalTexture.filterMode = FilterMode.Point;
            normalTexture.SetGlobalShaderProperty("_normalTexture");
        }

        if(lightTexture == null)
        {
            lightTexture = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            lightTexture.filterMode = FilterMode.Point;
            lightTexture.SetGlobalShaderProperty("_lightTexture");
        }

        // Cache a ref to our camera. 
        theCamera = GetComponent<Camera>();

        // Keep the planet green. 
        Application.targetFrameRate = -1;

        // Disable our buffer camera. 
        bufferCamera.enabled = false;
    }

    // As per https://docs.unity3d.com/Manual/ExecutionOrder.html, let's render our buffers right before Unity's internal rendering pipeline kicks in...
    private void OnPreRender()
    {
        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(theCamera.projectionMatrix, false);
        Matrix4x4 viewProjMatrix = projMatrix * theCamera.worldToCameraMatrix;
        Matrix4x4 inverseViewProjMatrix = viewProjMatrix.inverse;

        Shader.SetGlobalMatrix("_inverseViewProjMatrix", inverseViewProjMatrix);

        // Check to see if our ramp texture will change and update it. 
        UpdateRamp();

        // Render our normal and depth buffers...
        RenderDeferredPass();

        // Render our light volumes into our light texture. 
        RenderLight();

        // Reset the camera's culling mask. 
        ResetCamCullingMask();

        // Reset the camera's target texture, so Unity's default forward rendering path to the display takes over. 
        theCamera.targetTexture = null;
    }
    private void RenderDeferredPass()
    {
        ResetCamCullingMask();
        theCamera.backgroundColor = new Color(0,0,0,0);
        theCamera.clearFlags = CameraClearFlags.SolidColor;
        // Set camera values. 
        bufferCamera.CopyFrom(theCamera);
        bufferCamera.SetTargetBuffers(normalTexture.colorBuffer, depthTexture.depthBuffer); 
        bufferCamera.RenderWithShader(depthNormalShader, null);
    }

    private void RenderLight()
    {
        theCamera.backgroundColor = Color.black;
        theCamera.targetTexture = lightTexture;
        // Set the culling mask to "Light".
        theCamera.cullingMask = 1 << 3;
        bufferCamera.CopyFrom(theCamera);
        bufferCamera.RenderWithShader(lightShader, null );
    }

    private void ResetCamCullingMask()
    {
        // Set the culling mask to "Default". 
        theCamera.cullingMask = 1 << 0;
    }

    private void UpdateRamp()
    {
        if( _currentRamp != rampChoice )
        {
            if (rampChoice < 0 )
            {
                rampChoice = 0;
            }

            if (rampChoice >= rampStyles.Length)
            {
                rampChoice = rampStyles.Length - 1;
            }

            _currentRamp = rampChoice;

            Shader.SetGlobalTexture("_globalRamp", rampStyles[_currentRamp].Ramp);
            Shader.SetGlobalTexture("_globalSkyboxTexture", rampStyles[_currentRamp].Skybox);
            Shader.SetGlobalColor("_globalFogColour", rampStyles[_currentRamp].FogColour);
        }

        if( lightDirectionChoice != _currentLightDirection)
        {
            _currentLightDirection = lightDirectionChoice;

            // Convert from Unity's usual Euler angles to a normalised direction vector which we'll feed to the shader. 
            Shader.SetGlobalVector("_globalDefaultLightDir", Quaternion.Euler(_currentLightDirection) * Vector3.forward);
        }

        if(_currentFogFade != fogFadeFactor)
        {
            _currentFogFade = fogFadeFactor;

            Shader.SetGlobalFloat("_globalFogFadeFactor", _currentFogFade);
        }
    }
}


#if UNITY_EDITOR
class RenderTextureInspector : EditorWindow 
{
    [MenuItem("Toon Buffers/Show Toon Buffers")]
    static void Initialize()
    {
        RenderTextureInspector window  = (RenderTextureInspector)EditorWindow.GetWindow(typeof(RenderTextureInspector), true, "Buffers");
        window.Show();
    }

    void OnGUI () 
    {
        GUI.Box(new Rect(0, 0, position.width, position.height / 3), Shader.GetGlobalTexture("_depthTexture"));
        GUI.Box(new Rect(0, (position.height / 3) *1, position.width, position.height / 3), Shader.GetGlobalTexture("_normalTexture"));
        GUI.Box(new Rect(0, (position.height / 3) *2, position.width, position.height / 3), Shader.GetGlobalTexture("_lightTexture"));
    }
}
#endif
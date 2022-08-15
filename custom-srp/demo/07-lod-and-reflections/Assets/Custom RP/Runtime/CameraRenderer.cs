using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{
    const string bufferName = "Render Camera";

    static ShaderTagId
        unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit"),
        litShaderTagId = new ShaderTagId("CustomLit");

    internal static class ShaderPropertyId
    {
        public static readonly int time = Shader.PropertyToID("_Time");
        public static readonly int sinTime = Shader.PropertyToID("_SinTime");
        public static readonly int cosTime = Shader.PropertyToID("_CosTime");
        public static readonly int deltaTime = Shader.PropertyToID("unity_DeltaTime");
        public static readonly int timeParameters = Shader.PropertyToID("_TimeParameters");
    }


    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    ScriptableRenderContext context;

    Camera camera;

    CullingResults cullingResults;

    Lighting lighting = new Lighting();

    public void Render(
        ScriptableRenderContext context, Camera camera,
        bool useDynamicBatching, bool useGPUInstancing,
        ShadowSettings shadowSettings
    )
    {
        this.context = context;
        this.camera = camera;

        PrepareBuffer();
        PrepareForSceneWindow();
        if (!Cull(shadowSettings.maxDistance))
        {
            return;
        }
        
        buffer.BeginSample(SampleName);
        SetShaderTimeValues();
        ExecuteBuffer();
        lighting.Setup(context, cullingResults, shadowSettings);
        buffer.EndSample(SampleName);
        Setup();
        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
        DrawUnsupportedShaders();
        DrawGizmos();
        lighting.Cleanup();
        Submit();
    }

    bool Cull(float maxShadowDistance)
    {
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
            cullingResults = context.Cull(ref p);
            return true;
        }

        return false;
    }

    void Setup()
    {
        context.SetupCameraProperties(camera);
        CameraClearFlags flags = camera.clearFlags;
        buffer.ClearRenderTarget(
            flags <= CameraClearFlags.Depth,
            flags == CameraClearFlags.Color,
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear
        );
        buffer.BeginSample(SampleName);
        ExecuteBuffer();
    }

    void Submit()
    {
        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing)
    {
        var sortingSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque
        };
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings)
        {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing,
            perObjectData =
                PerObjectData.ReflectionProbes |
                PerObjectData.Lightmaps | PerObjectData.ShadowMask |
                PerObjectData.LightProbe | PerObjectData.OcclusionProbe |
                PerObjectData.LightProbeProxyVolume |
                PerObjectData.OcclusionProbeProxyVolume
        };
        drawingSettings.SetShaderPassName(1, litShaderTagId);

        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;

        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }
    
    /// <summary>
    /// Set shader time variables as described in https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
    /// </summary>
    /// <param name="buffer">CommandBuffer to submit data to GPU.</param>
    /// <param name="time">Time.</param>
    /// <param name="deltaTime">Delta time.</param>
    /// <param name="smoothDeltaTime">Smooth delta time.</param>
    void SetShaderTimeValues()
    {
#if UNITY_EDITOR
        float time = Application.isPlaying ? Time.time : Time.realtimeSinceStartup;
#else
        float time = Time.time;
#endif
        float deltaTime = Time.deltaTime;
        float smoothDeltaTime = Time.smoothDeltaTime;

        float timeEights = time / 8f;
        float timeFourth = time / 4f;
        float timeHalf = time / 2f;

        // Time values
        Vector4 timeVector = time * new Vector4(1f / 20f, 1f, 2f, 3f);
        Vector4 sinTimeVector = new Vector4(Mathf.Sin(timeEights), Mathf.Sin(timeFourth), Mathf.Sin(timeHalf), Mathf.Sin(time));
        Vector4 cosTimeVector = new Vector4(Mathf.Cos(timeEights), Mathf.Cos(timeFourth), Mathf.Cos(timeHalf), Mathf.Cos(time));
        Vector4 deltaTimeVector = new Vector4(deltaTime, 1f / deltaTime, smoothDeltaTime, 1f / smoothDeltaTime);
        Vector4 timeParametersVector = new Vector4(time, Mathf.Sin(time), Mathf.Cos(time), 0.0f);

        buffer.SetGlobalVector(ShaderPropertyId.time, timeVector);
        buffer.SetGlobalVector(ShaderPropertyId.sinTime, sinTimeVector);
        buffer.SetGlobalVector(ShaderPropertyId.cosTime, cosTimeVector);
        buffer.SetGlobalVector(ShaderPropertyId.deltaTime, deltaTimeVector);
        buffer.SetGlobalVector(ShaderPropertyId.timeParameters, timeParametersVector);
    }
}
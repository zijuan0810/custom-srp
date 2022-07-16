using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{
    private const string bufferName = "Lighting";
    private const int maxDirLightCount = 4;

    private static int
        dirLightCountId = Shader.PropertyToID("_DirectionalLightCount"),
        dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors"),
        dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections");

    private static Vector4[]
        dirLightColors = new Vector4[maxDirLightCount],
        dirLightDirections = new Vector4[maxDirLightCount];

    private CommandBuffer _buffer = new CommandBuffer {name = bufferName};

    private CullingResults _cullingResults;

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults)
    {
        _cullingResults = cullingResults;

        _buffer.BeginSample(bufferName);
        SetupLights();
        _buffer.EndSample(bufferName);

        context.ExecuteCommandBuffer(_buffer);
        _buffer.Clear();
    }

    private void SetupLights()
    {
        NativeArray<VisibleLight> visibleLights = _cullingResults.visibleLights;
        int dirLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight visibleLight = visibleLights[i];
            if (visibleLight.lightType == LightType.Directional)
            {
                SetupDiectionalLight(dirLightCount++, ref visibleLight);
                if (dirLightCount >= maxDirLightCount)
                    break;
            }
        }

        _buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        _buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
        _buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
    }

    private void SetupDiectionalLight(int index, ref VisibleLight visibleLight)
    {
        // Light light = RenderSettings.sun;
        // buffer.SetGlobalVector(dirLightColorId, light.color.linear * light.intensity);
        // buffer.SetGlobalVector(dirLightDirectionId, -light.transform.forward);

        dirLightColors[index] = visibleLight.finalColor;
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
    }
}
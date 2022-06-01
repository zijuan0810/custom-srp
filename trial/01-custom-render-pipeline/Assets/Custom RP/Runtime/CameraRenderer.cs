using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CameraRenderer
{
	ScriptableRenderContext context;
	Camera camera;

	const string bufferName = "Render Camera";

	CommandBuffer buffer = new CommandBuffer { name = bufferName };
	CullingResults cullingResults;

	static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");

	public void Render(ScriptableRenderContext context, Camera camera)
	{
		this.context = context;
		this.camera = camera;

		if (!Cull())
			return;

		Setup();
		DrawVisibleGeometry();
		Submit();
	}

	private bool Cull()
	{
		if (camera.TryGetCullingParameters(out ScriptableCullingParameters  p))
		{
			cullingResults = context.Cull(ref p);
			return true;
		}

		return false;
	}

	private void Setup()
	{
		context.SetupCameraProperties(camera);
		buffer.ClearRenderTarget(true, true, Color.clear);
		buffer.BeginSample(bufferName);
		ExecuteBuffer();
	}

	private void Submit()
	{
		buffer.EndSample(bufferName);
		ExecuteBuffer();
		context.Submit();
	}

	private void ExecuteBuffer()
	{
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}

	private void DrawVisibleGeometry()
	{
		var sortingSettins = new SortingSettings(camera) { criteria = SortingCriteria.CommonOpaque };
		var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettins);
		var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
		context.DrawSkybox(camera);

		sortingSettins.criteria = SortingCriteria.CommonTransparent;
		drawingSettings.sortingSettings = sortingSettins;
		filteringSettings.renderQueueRange = RenderQueueRange.transparent;
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
	}
}

﻿using System.Collections;

		//As that might add geometry to the scene it has to be done before culling
		PrepareBuffer();
		PrepareForSceneWindow();

		if (!Cull())
		//From 1 to 4 they are Skybox, Color, Depth, and Nothing.
		CameraClearFlags flags = camera.clearFlags;
			flags == CameraClearFlags.Color,
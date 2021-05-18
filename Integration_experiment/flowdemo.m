classdef flowdemo < gaglab.core.experiment
	
	properties (GetAccess = public, SetAccess = private)
		world
		wall
		dotField
	end
	
	properties (Access = private)
		dotMesh
	end
	
	methods (Access = protected)
		function configure (this)
			% Create 3D scene component
			this.world = usePlugin(this, "gaglab3d");
            this.world.options.maxLogLevel = 0;
			this.world.options.maxNumMessages = 4096;
			this.world.controller.enabled = false;
		end
		
		function startup (this)
			% Wall
			this.wall = createWalls(this, [-10 -10], [10 -10], 10);
			
			this.world.observer.position = [0 1 0];
			this.world.observer.orientation(1) = -6;
			
			L = addLight(this.world.observer, "Light", "", "LIGHTING", "SHADOWMAP");
			L.position = [0 1 0];
			L.orientation(1) = -90;
			L.fieldOfView = 360;
			L.shadowMapCount = 1;
			L.colorMultiplier = 1;
			
			setupDotField(this, this.configData.Setup);
			setupTrajectories(this, this.configData.Trajectories);
		end
		
		function setupDotField (this, setup)
			if ~isempty(this.dotField) && isvalid(this.dotField)
				delete(this.dotField);
			end
			this.dotField = dotfield.dotfield(this, ...
                'boundingBox', [-10 -0.1 -10; 10 0 0], ...
				'diameter', setup.Diameter, ...
				'density', setup.Density, ...
				'lifetime', setup.Lifetime, ...
				'burstiness', setup.Burstiness, ...
				'colored', setup.Colored, ...
				'translationRange', [ ...
				-setup.MaxHorizontal, -setup.MaxVertical, -setup.MaxDepth;
				setup.MaxHorizontal,  setup.MaxVertical,  setup.MaxDepth], ...
				'pitchRange', [-setup.MaxPitch, setup.MaxPitch], ...
				'yawRange', [-setup.MaxYaw, setup.MaxYaw], ...
				'rollRange', [-setup.MaxRoll, setup.MaxRoll], ...
				'gravityRange', [0,setup.MaxGravity]);
			this.dotMesh = [this.dotField.node.children.children];
		end
		
		function setupTrajectories (this, trajectory)
			for i=1:height(trajectory)
				T = dotfield.trial(this.dotField, 0, trajectory.Duration(i));
				T.replacement = trajectory.Replacement(i);
				T.coherence = trajectory.Coherence(i);
				T.horizontal = trajectory.Horizontal(i);
				T.vertical = trajectory.Vertical(i);
				T.depth = trajectory.Depth(i);
				T.pitch = trajectory.Pitch(i);
				T.yaw = trajectory.Yaw(i);
				T.roll = trajectory.Roll(i);
				T.gravity = trajectory.Gravity(i);
				T.startFcn = @(~,~,~)modifyBackground(trajectory.Fix{i}, trajectory.Visible(i));
			end
			
			function modifyBackground (imageName, isvisible)
				this.wall.children.material.sampler.albedoMap = imageName;
				[this.dotMesh.visible] = deal(isvisible);
				%[this.dotField.dots.castShadow] = deal(isvisible);
				%[this.dotField.dots.rayQuery] = deal(isvisible);
			end
		end
		
		function floor = createFloor (this, startPoint, endPoint, height)
			floor = gaglab3d.shape.plane([startPoint(1);height;startPoint(2)], ...
				[endPoint(1);height;endPoint(2)], "z");
			floor.name = "Floor";
			floor.tileSize = 2;
			floor = addShapes(this.world.scene, floor, "Floor", "model");
			%floor.children.material.sampler.albedoMap = "floor";
			floor.children.material.uniform.matDiffuseCol = [0 0 0 1];
		end
		
		function wall = createWalls (this, startPoint, endPoint, height)
			plane = gaglab3d.shape.plane([startPoint(1);0;startPoint(2)], ...
				[endPoint(1);height;endPoint(2)], "y");
			plane.name = "Wall";
			plane.tileSize = 0;
			wall = addShapes(this.world.scene, plane, "Wall", "model");
			wall.children.material.sampler.albedoMap = "sky";
			wall.children.material.uniform.matDiffuseCol = [1 1 1 1];
		end
	end
end


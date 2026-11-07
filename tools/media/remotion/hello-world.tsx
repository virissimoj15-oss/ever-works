import React from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame } from 'remotion';

export const HelloWorld: React.FC = () => {
	const frame = useCurrentFrame();
	const opacity = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: 'clamp' });
	const scale = interpolate(frame, [0, 60], [0.8, 1.1]);

	return (
		<AbsoluteFill style={{ backgroundColor: '#0f172a', justifyContent: 'center', alignItems: 'center' }}>
			<h1
				style={{
					color: 'white',
					fontSize: 96,
					fontFamily: 'sans-serif',
					opacity,
					transform: `scale(${scale})`
				}}
			>
				Remotion OK
			</h1>
		</AbsoluteFill>
	);
};

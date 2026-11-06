import React from 'react';
import { Composition } from 'remotion';
import { HelloWorld } from './hello-world';

export const RemotionRoot: React.FC = () => (
	<Composition id="HelloWorld" component={HelloWorld} durationInFrames={60} fps={30} width={1280} height={720} />
);

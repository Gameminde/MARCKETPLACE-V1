import React, { useRef, useMemo, useState, useEffect, useCallback } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Points, PointMaterial } from '@react-three/drei';
import * as THREE from 'three';

interface ParticleSystemProps {
  className?: string;
  palette?: {
    purple?: string;
    pink?: string;
    orange?: string;
    cyan?: string;
    lime?: string;
  };
}

interface ParticleFieldProps {
  palette: NonNullable<ParticleSystemProps['palette']>;
}

const ParticleField: React.FC<ParticleFieldProps> = ({ palette }) => {
  const ref = useRef<THREE.Points>(null);
  const geometryRef = useRef<THREE.BufferGeometry>(null);
  
  const [particlesPosition, particleColors] = useMemo(() => {
    const positions = new Float32Array(2000 * 3);
    const colors = new Float32Array(2000 * 3);
    
    const colorPalette = [
      new THREE.Color(palette.purple || '#8B5CF6'),
      new THREE.Color(palette.pink || '#EC4899'),
      new THREE.Color(palette.orange || '#F59E0B'),
      new THREE.Color(palette.cyan || '#06B6D4'),
      new THREE.Color(palette.lime || '#84CC16')
    ];
    
    for (let i = 0; i < 2000; i++) {
      const i3 = i * 3;
      positions[i3] = (Math.random() - 0.5) * 20;
      positions[i3 + 1] = (Math.random() - 0.5) * 20;
      positions[i3 + 2] = (Math.random() - 0.5) * 20;
      
      const color = colorPalette[Math.floor(Math.random() * colorPalette.length)];
      colors[i3] = color.r;
      colors[i3 + 1] = color.g;
      colors[i3 + 2] = color.b;
    }
    
    return [positions, colors];
  }, [palette]);

  // Cleanup function to prevent memory leaks
  const cleanup = useCallback(() => {
    if (geometryRef.current) {
      geometryRef.current.dispose();
    }
  }, []);

  useEffect(() => {
    return cleanup;
  }, [cleanup]);

  useFrame((state) => {
    if (!ref.current?.geometry?.attributes?.position) {
      return;
    }
    
    // Smooth rotation animation
    ref.current.rotation.x = state.clock.elapsedTime * 0.05;
    ref.current.rotation.y = state.clock.elapsedTime * 0.02;
    
    // Animate particle positions with null safety
    const positionAttribute = ref.current.geometry.attributes.position;
    if (positionAttribute && positionAttribute.array) {
      const positions = positionAttribute.array as Float32Array;
      
      for (let i = 0; i < positions.length; i += 3) {
        positions[i + 1] += Math.sin(state.clock.elapsedTime + positions[i]) * 0.001;
      }
      
      positionAttribute.needsUpdate = true;
    }
  });

  return (
    <Points ref={ref} positions={particlesPosition}>
      <bufferGeometry ref={geometryRef}>
        <bufferAttribute
          attach="attributes-position"
          args={[particlesPosition, 3]}
        />
        <bufferAttribute
          attach="attributes-color"
          args={[particleColors, 3]}
        />
      </bufferGeometry>
      <PointMaterial
        transparent
        vertexColors
        size={0.02}
        sizeAttenuation={true}
        depthWrite={false}
        blending={THREE.AdditiveBlending}
      />
    </Points>
  );
};

// Error boundary component for 3D rendering
const ParticleErrorBoundary: React.FC<{ children: React.ReactNode; fallback?: React.ReactNode }> = ({ 
  children, 
  fallback = null 
}) => {
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    const handleError = () => setHasError(true);
    window.addEventListener('error', handleError);
    return () => window.removeEventListener('error', handleError);
  }, []);

  if (hasError) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
};

export const ParticleSystem: React.FC<ParticleSystemProps> = ({ 
  className = "absolute inset-0 -z-20",
  palette = {
    purple: '#8B5CF6',
    pink: '#EC4899',
    orange: '#F59E0B',
    cyan: '#06B6D4',
    lime: '#84CC16'
  }
}) => {
  const [isReady, setIsReady] = useState(false);
  const [hasWebGL, setHasWebGL] = useState(false);

  useEffect(() => {
    // Check for Three.js availability
    const checkThreeJS = () => {
      try {
        return typeof THREE !== 'undefined' && THREE.WebGLRenderer;
      } catch {
        return false;
      }
    };

    // Check for WebGL support
    const checkWebGL = () => {
      try {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        return !!gl;
      } catch {
        return false;
      }
    };

    const threeReady = checkThreeJS();
    const webglSupported = checkWebGL();
    
    setIsReady(threeReady);
    setHasWebGL(webglSupported);
  }, []);

  // Fallback for unsupported environments
  if (!isReady || !hasWebGL) {
    return (
      <div className={className}>
        <div className="absolute inset-0 bg-gradient-to-br from-purple-500/10 via-pink-500/10 to-cyan-500/10" />
      </div>
    );
  }

  return (
    <div className={className}>
      <ParticleErrorBoundary
        fallback={
          <div className="absolute inset-0 bg-gradient-to-br from-purple-500/10 via-pink-500/10 to-cyan-500/10" />
        }
      >
        <Canvas
          camera={{ position: [0, 0, 5], fov: 75 }}
          style={{ background: 'transparent' }}
          gl={{ 
            antialias: false, // Improve performance
            alpha: true,
            powerPreference: 'high-performance'
          }}
          dpr={Math.min(window.devicePixelRatio, 2)} // Limit pixel ratio for performance
        >
          <ParticleField palette={palette} />
        </Canvas>
      </ParticleErrorBoundary>
    </div>
  );
};

export default ParticleSystem;
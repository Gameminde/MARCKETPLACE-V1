import React, { useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float, Sphere, Torus, Box } from '@react-three/drei';
import * as THREE from 'three';

interface FloatingShapeProps {
  position: [number, number, number];
  color: string;
  type: 'sphere' | 'torus' | 'box';
  scale?: number;
}

const FloatingShape: React.FC<FloatingShapeProps> = ({ 
  position, 
  color, 
  type, 
  scale = 1 
}) => {
  const meshRef = useRef<THREE.Mesh>(null);

  useFrame((state) => {
    if (meshRef.current) {
      meshRef.current.rotation.x = state.clock.elapsedTime * 0.5;
      meshRef.current.rotation.y = state.clock.elapsedTime * 0.3;
    }
  });

  const material = useMemo(
    () => (
      <meshStandardMaterial
        color={color}
        emissive={color}
        emissiveIntensity={0.2}
        roughness={0.1}
        metalness={0.8}
        transparent
        opacity={0.8}
      />
    ),
    [color]
  );

  return (
    <Float
      speed={1.5}
      rotationIntensity={1}
      floatIntensity={2}
      floatingRange={[-0.5, 0.5]}
    >
      <mesh ref={meshRef} position={position} scale={scale}>
        {type === 'sphere' && <Sphere args={[1, 32, 32]} />}
        {type === 'torus' && <Torus args={[1, 0.4, 16, 100]} />}
        {type === 'box' && <Box args={[1.5, 1.5, 1.5]} />}
        {material}
      </mesh>
    </Float>
  );
};

const Scene: React.FC = () => {
  const shapes = useMemo(() => [
    { position: [-4, 2, -2] as [number, number, number], color: '#8B5CF6', type: 'sphere' as const, scale: 0.8 },
    { position: [4, -1, -3] as [number, number, number], color: '#EC4899', type: 'torus' as const, scale: 0.6 },
    { position: [-2, -2, -1] as [number, number, number], color: '#F59E0B', type: 'box' as const, scale: 0.5 },
    { position: [3, 3, -4] as [number, number, number], color: '#06B6D4', type: 'sphere' as const, scale: 0.7 },
    { position: [0, -3, -2] as [number, number, number], color: '#84CC16', type: 'torus' as const, scale: 0.4 },
  ], []);

  return (
    <>
      <ambientLight intensity={0.3} />
      <pointLight position={[10, 10, 10]} intensity={1} color="#8B5CF6" />
      <pointLight position={[-10, -10, -10]} intensity={0.5} color="#EC4899" />
      
      {shapes.map((shape, index) => (
        <FloatingShape
          key={index}
          position={shape.position}
          color={shape.color}
          type={shape.type}
          scale={shape.scale}
        />
      ))}
    </>
  );
};

export const FloatingElements: React.FC<{ className?: string }> = ({ 
  className = "absolute inset-0 -z-10" 
}) => {
  return (
    <div className={className}>
      <Canvas
        camera={{ position: [0, 0, 5], fov: 60 }}
        style={{ background: 'transparent' }}
      >
        <Scene />
      </Canvas>
    </div>
  );
};

export default FloatingElements;
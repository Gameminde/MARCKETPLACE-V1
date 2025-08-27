import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  Cpu, 
  Palette, 
  Zap, 
  Settings, 
  Play, 
  Square,
  CheckCircle,
  AlertCircle
} from 'lucide-react';
import { NeonCard } from '@/components/ui/neon-card';
import { NeonButton } from '@/components/ui/neon-button';
import { GlassCard } from '@/components/ui/glass-card';
import { Badge } from '@/components/ui/badge';
import { mcpIntegration, type MCPServer, type DesignRequest } from '@/lib/mcp-integration';

interface MCPControllerProps {
  onDesignGenerated?: (result: any) => void;
}

const MCPController: React.FC<MCPControllerProps> = ({ onDesignGenerated }) => {
  const [servers, setServers] = useState<MCPServer[]>([]);
  const [activeServers, setActiveServers] = useState<Set<string>>(new Set());
  const [isProcessing, setIsProcessing] = useState(false);
  const [lastResult, setLastResult] = useState<any>(null);

  useEffect(() => {
    setServers(mcpIntegration.getAvailableServers());
  }, []);

  const handleServerToggle = (serverName: string) => {
    const newActiveServers = new Set(activeServers);
    if (newActiveServers.has(serverName)) {
      newActiveServers.delete(serverName);
    } else {
      newActiveServers.add(serverName);
    }
    setActiveServers(newActiveServers);
  };

  const processDesignRequest = async (request: DesignRequest) => {
    setIsProcessing(true);
    try {
      const result = await mcpIntegration.processDesignRequest(request);
      setLastResult(result);
      onDesignGenerated?.(result);
    } catch (error) {
      console.error('MCP processing error:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const getServerIcon = (serverName: string) => {
    switch (serverName) {
      case 'threejs': return <Cpu className="h-5 w-5" />;
      case 'figma': return <Palette className="h-5 w-5" />;
      case 'framer-motion': return <Zap className="h-5 w-5" />;
      default: return <Settings className="h-5 w-5" />;
    }
  };

  const getServerStatus = (serverName: string) => {
    return activeServers.has(serverName) ? 'active' : 'inactive';
  };

  return (
    <div className="space-y-6">
      {/* MCP Status Header */}
      <NeonCard variant="holographic" className="p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-xl font-bold bg-gradient-primary bg-clip-text text-transparent">
            MCP Design Engine
          </h3>
          <Badge variant={activeServers.size > 0 ? "default" : "secondary"}>
            {activeServers.size} Active
          </Badge>
        </div>
        <p className="text-muted-foreground">
          Model Context Protocol servers for advanced design generation and optimization
        </p>
      </NeonCard>

      {/* Server Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {servers.map((server) => {
          const isActive = activeServers.has(server.name.toLowerCase().replace(/\s+/g, '-'));
          const status = getServerStatus(server.name.toLowerCase().replace(/\s+/g, '-'));
          
          return (
            <motion.div
              key={server.name}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <GlassCard 
                variant={isActive ? "premium" : "default"}
                className={`cursor-pointer transition-all duration-300 ${
                  isActive ? 'border-primary/50 shadow-glow' : 'hover:border-primary/30'
                }`}
                onClick={() => handleServerToggle(server.name.toLowerCase().replace(/\s+/g, '-'))}
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-2">
                    {getServerIcon(server.name.toLowerCase().replace(/\s+/g, '-'))}
                    <span className="font-medium">{server.name}</span>
                  </div>
                  {isActive ? (
                    <CheckCircle className="h-5 w-5 text-green-500" />
                  ) : (
                    <Square className="h-5 w-5 text-muted-foreground" />
                  )}
                </div>
                
                <div className="space-y-2">
                  <div className="text-xs text-muted-foreground">
                    Status: <span className={isActive ? 'text-green-500' : 'text-orange-500'}>
                      {status}
                    </span>
                  </div>
                  
                  <div className="flex flex-wrap gap-1">
                    {server.capabilities.slice(0, 3).map((capability) => (
                      <Badge key={capability} variant="outline" className="text-xs">
                        {capability}
                      </Badge>
                    ))}
                    {server.capabilities.length > 3 && (
                      <Badge variant="outline" className="text-xs">
                        +{server.capabilities.length - 3}
                      </Badge>
                    )}
                  </div>
                </div>
              </GlassCard>
            </motion.div>
          );
        })}
      </div>

      {/* Quick Actions */}
      <NeonCard variant="electric" className="p-6">
        <h4 className="text-lg font-semibold mb-4">Quick Design Actions</h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <NeonButton
            variant="neon"
            size="sm"
            disabled={isProcessing || activeServers.size === 0}
            onClick={() => processDesignRequest({
              type: '3d',
              prompt: 'Generate modern 3D product showcase with glassmorphism effects'
            })}
          >
            {isProcessing ? <Zap className="h-4 w-4 animate-spin" /> : <Cpu className="h-4 w-4" />}
            3D Scene
          </NeonButton>
          
          <NeonButton
            variant="cyber"
            size="sm"
            disabled={isProcessing || activeServers.size === 0}
            onClick={() => processDesignRequest({
              type: 'ui',
              prompt: 'Create premium marketplace UI components with neon effects'
            })}
          >
            <Palette className="h-4 w-4" />
            UI Design
          </NeonButton>
          
          <NeonButton
            variant="electric"
            size="sm"
            disabled={isProcessing || activeServers.size === 0}
            onClick={() => processDesignRequest({
              type: 'animation',
              prompt: 'Add smooth micro-interactions and page transitions'
            })}
          >
            <Zap className="h-4 w-4" />
            Animations
          </NeonButton>
          
          <NeonButton
            variant="ghost"
            size="sm"
            disabled={isProcessing || activeServers.size === 0}
            onClick={() => processDesignRequest({
              type: 'performance',
              prompt: 'Optimize marketplace for better performance and loading'
            })}
          >
            <Settings className="h-4 w-4" />
            Optimize
          </NeonButton>
        </div>
      </NeonCard>

      {/* Results Display */}
      {lastResult && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <GlassCard variant="feature" className="p-6">
            <div className="flex items-center space-x-2 mb-4">
              {lastResult.success ? (
                <CheckCircle className="h-5 w-5 text-green-500" />
              ) : (
                <AlertCircle className="h-5 w-5 text-red-500" />
              )}
              <h4 className="text-lg font-semibold">
                {lastResult.success ? 'Design Generated Successfully' : 'Generation Failed'}
              </h4>
            </div>
            
            {lastResult.success && lastResult.suggestions && (
              <div className="space-y-2">
                <h5 className="font-medium text-sm">Suggestions:</h5>
                <ul className="space-y-1">
                  {lastResult.suggestions.map((suggestion: string, index: number) => (
                    <li key={index} className="text-sm text-muted-foreground flex items-start space-x-2">
                      <span className="text-primary">•</span>
                      <span>{suggestion}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            
            {lastResult.error && (
              <div className="text-sm text-red-400">
                Error: {lastResult.error}
              </div>
            )}
          </GlassCard>
        </motion.div>
      )}
    </div>
  );
};

export default MCPController;
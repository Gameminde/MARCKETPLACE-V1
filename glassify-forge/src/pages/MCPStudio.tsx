import MCPController from '@/components/mcp/MCPController';
import { useState } from 'react';
import { motion } from 'framer-motion';
import { NeonCard } from '@/components/ui/neon-card';
import { GlassButton } from '@/components/ui/glass-button';
import { Sparkles, Zap, Cpu, Palette, Settings, Code } from 'lucide-react';

const MCPStudio = () => {
  const [designResults, setDesignResults] = useState<any[]>([]);

  const handleDesignGenerated = (result: any) => {
    setDesignResults(prev => [result, ...prev.slice(0, 4)]); // Keep last 5 results
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-surface to-background p-8">
      <div className="container mx-auto max-w-7xl">
        {/* Header */}
        <motion.div 
          className="text-center mb-12"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
        >
          <h1 className="text-4xl md:text-6xl font-black mb-4">
            <span className="bg-gradient-primary bg-clip-text text-transparent">
              MCP Design Studio
            </span>
          </h1>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto">
            Transform your marketplace with AI-powered design generation using 
            <span className="text-primary font-semibold"> Model Context Protocol</span> servers
          </p>
        </motion.div>
        
        {/* Stats Cards */}
        <motion.div 
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          <NeonCard variant="electric" className="text-center p-6">
            <Cpu className="h-8 w-8 text-primary mx-auto mb-3" />
            <h3 className="text-2xl font-bold text-foreground mb-2">10+</h3>
            <p className="text-muted-foreground">MCP Servers</p>
          </NeonCard>
          
          <NeonCard variant="cyber" className="text-center p-6">
            <Zap className="h-8 w-8 text-secondary mx-auto mb-3" />
            <h3 className="text-2xl font-bold text-foreground mb-2">Real-time</h3>
            <p className="text-muted-foreground">Design Generation</p>
          </NeonCard>
          
          <NeonCard variant="plasma" className="text-center p-6">
            <Sparkles className="h-8 w-8 text-accent mx-auto mb-3" />
            <h3 className="text-2xl font-bold text-foreground mb-2">AI-Powered</h3>
            <p className="text-muted-foreground">3D & UI Creation</p>
          </NeonCard>
        </motion.div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* MCP Controller */}
          <motion.div 
            className="lg:col-span-2"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
          >
            <MCPController onDesignGenerated={handleDesignGenerated} />
          </motion.div>

          {/* Results Panel */}
          <motion.div 
            className="space-y-6"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.6 }}
          >
            <NeonCard variant="holographic" className="p-6">
              <h3 className="text-lg font-bold mb-4 bg-gradient-secondary bg-clip-text text-transparent">
                Recent Generations
              </h3>
              
              {designResults.length === 0 ? (
                <div className="text-center py-8">
                  <Sparkles className="h-12 w-12 text-muted-foreground mx-auto mb-3 opacity-50" />
                  <p className="text-muted-foreground text-sm">
                    No designs generated yet.
                    <br />Start by activating MCP servers!
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {designResults.map((result, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.3, delay: index * 0.1 }}
                      className="glass-card p-4 border border-primary/20"
                    >
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-foreground">
                          Generation #{designResults.length - index}
                        </span>
                        <span className={`text-xs px-2 py-1 rounded ${
                          result.success 
                            ? 'bg-green-500/20 text-green-400' 
                            : 'bg-red-500/20 text-red-400'
                        }`}>
                          {result.success ? 'Success' : 'Failed'}
                        </span>
                      </div>
                      
                      {result.success && result.suggestions && (
                        <div className="text-xs text-muted-foreground">
                          {result.suggestions[0]}
                        </div>
                      )}
                    </motion.div>
                  ))}
                </div>
              )}
            </NeonCard>

            {/* Quick Actions */}
            <NeonCard variant="default" className="p-6">
              <h4 className="text-md font-semibold mb-4 text-foreground">
                Quick Start
              </h4>
              <div className="space-y-3">
                <GlassButton variant="hero" className="w-full text-sm">
                  <Palette className="h-4 w-4" />
                  Load Figma Design
                </GlassButton>
                <GlassButton variant="glass" className="w-full text-sm">
                  <Code className="h-4 w-4" />
                  Export to Code
                </GlassButton>
                <GlassButton variant="outline" className="w-full text-sm">
                  <Settings className="h-4 w-4" />
                  View Documentation
                </GlassButton>
              </div>
            </NeonCard>

            {/* Installation Guide */}
            <NeonCard variant="cyber" className="p-6">
              <h4 className="text-md font-semibold mb-4 text-foreground">
                Installation Status
              </h4>
              <div className="space-y-2 text-sm">
                <div className="flex items-center justify-between">
                  <span>Figma MCP</span>
                  <span className="text-green-400">✓ Ready</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Three.js MCP</span>
                  <span className="text-yellow-400">⚠ Pending</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Tailwind MCP</span>
                  <span className="text-green-400">✓ Ready</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Framer Motion MCP</span>
                  <span className="text-yellow-400">⚠ Pending</span>
                </div>
              </div>
              
              <GlassButton variant="outline" size="sm" className="w-full mt-4">
                Install Missing MCPs
              </GlassButton>
            </NeonCard>
          </motion.div>
        </div>

        {/* Footer CTA */}
        <motion.div 
          className="mt-16 text-center"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.8 }}
        >
          <NeonCard variant="plasma" className="p-8 max-w-2xl mx-auto">
            <h3 className="text-2xl font-bold mb-4 text-foreground">
              Ready to Transform Your Marketplace?
            </h3>
            <p className="text-muted-foreground mb-6">
              Use the power of MCP servers to generate stunning 3D designs, 
              modern UI components, and smooth animations.
            </p>
            <GlassButton variant="premium" size="lg">
              <Sparkles className="h-5 w-5" />
              Start Creating Now
            </GlassButton>
          </NeonCard>
        </motion.div>
      </div>
    </div>
  );
};

export default MCPStudio;
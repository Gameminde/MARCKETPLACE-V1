import { ArrowRight, Sparkles } from "lucide-react";
import { NeonButton } from "@/components/ui/neon-button";
import { NeonCard } from "@/components/ui/neon-card";
import { FloatingElements } from "@/components/3d/FloatingElements";
import { ParticleSystem } from "@/components/3d/ParticleSystem";
import { motion } from "framer-motion";
// import heroBackground from "@/assets/hero-background.jpg";

const HeroSection = () => {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* 3D Background Elements */}
      <ParticleSystem />
      <FloatingElements />
      
      {/* Background with Neon Overlay */}
      <div className="absolute inset-0 z-0 bg-gradient-hero" />

      {/* Animated Floating Orbs */}
      <div className="absolute inset-0 z-10">
        <motion.div 
          className="absolute top-20 left-[10%] w-32 h-32 rounded-full bg-gradient-secondary blur-xl opacity-30"
          animate={{
            y: [-20, 20, -20],
            rotate: [0, 180, 360],
            scale: [1, 1.2, 1],
          }}
          transition={{
            duration: 8,
            repeat: Infinity,
            ease: "easeInOut",
          }}
        />
        <motion.div 
          className="absolute top-40 right-[15%] w-24 h-24 rounded-full bg-gradient-primary blur-lg opacity-40"
          animate={{
            y: [20, -20, 20],
            rotate: [360, 180, 0],
            scale: [1.2, 1, 1.2],
          }}
          transition={{
            duration: 6,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 1,
          }}
        />
        <motion.div 
          className="absolute bottom-20 left-[20%] w-40 h-40 rounded-full bg-gradient-neon blur-2xl opacity-20"
          animate={{
            y: [-30, 30, -30],
            rotate: [0, -180, -360],
            scale: [1, 1.5, 1],
          }}
          transition={{
            duration: 10,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 2,
          }}
        />
      </div>

      {/* Main Content */}
      <div className="relative z-20 container mx-auto px-4 text-center">
        <motion.div 
          className="max-w-4xl mx-auto space-y-8"
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, ease: "easeOut" }}
        >
          {/* Hero Badge */}
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2, duration: 0.8 }}
          >
            <NeonCard variant="holographic" className="inline-flex items-center space-x-2 px-6 py-3">
              <Sparkles className="h-5 w-5 text-primary animate-pulse" />
              <span className="text-sm font-bold bg-gradient-primary bg-clip-text text-transparent">
                NEXT-GEN MARKETPLACE
              </span>
            </NeonCard>
          </motion.div>

          {/* Main Headline */}
          <motion.div 
            className="space-y-6"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.8 }}
          >
            <h1 className="text-6xl md:text-8xl font-black leading-none tracking-tight">
              <span className="bg-gradient-primary bg-clip-text text-transparent">
                DISCOVER
              </span>
              <br />
              <span className="bg-gradient-secondary bg-clip-text text-transparent">
                THE FUTURE
              </span>
            </h1>
            <p className="text-xl md:text-2xl font-medium text-foreground/80 max-w-3xl mx-auto leading-relaxed">
              Experience the ultimate marketplace revolution with 
              <span className="bg-gradient-neon bg-clip-text text-transparent font-bold"> 3D interactions</span>, 
              <span className="bg-gradient-primary bg-clip-text text-transparent font-bold"> AI-powered discovery</span>, 
              and <span className="bg-gradient-secondary bg-clip-text text-transparent font-bold">limitless possibilities</span>.
            </p>
          </motion.div>

          {/* Call to Action */}
          <motion.div 
            className="flex flex-col sm:flex-row items-center justify-center space-y-4 sm:space-y-0 sm:space-x-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6, duration: 0.8 }}
          >
            <NeonButton variant="neon" size="xl" className="group">
              <Sparkles className="h-5 w-5" />
              Explore Marketplace
              <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-2" />
            </NeonButton>
            <NeonButton variant="cyber" size="xl">
              Start Selling Today
            </NeonButton>
          </motion.div>

          {/* Stats */}
          <motion.div 
            className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-20"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8, duration: 0.8 }}
          >
            <NeonCard variant="electric" floating className="text-center">
              <motion.div 
                className="text-4xl md:text-5xl font-black bg-gradient-primary bg-clip-text text-transparent mb-3"
                whileHover={{ scale: 1.1 }}
              >
                100K+
              </motion.div>
              <div className="text-foreground/70 font-medium">Active Products</div>
            </NeonCard>
            <NeonCard variant="cyber" floating className="text-center">
              <motion.div 
                className="text-4xl md:text-5xl font-black bg-gradient-secondary bg-clip-text text-transparent mb-3"
                whileHover={{ scale: 1.1 }}
              >
                25K+
              </motion.div>
              <div className="text-foreground/70 font-medium">Verified Sellers</div>
            </NeonCard>
            <NeonCard variant="plasma" floating className="text-center">
              <motion.div 
                className="text-4xl md:text-5xl font-black bg-gradient-neon bg-clip-text text-transparent mb-3"
                whileHover={{ scale: 1.1 }}
              >
                500K+
              </motion.div>
              <div className="text-foreground/70 font-medium">Happy Customers</div>
            </NeonCard>
          </motion.div>
        </motion.div>
      </div>
      
      {/* Scanning Line Effect */}
      <motion.div
        className="absolute bottom-0 left-0 w-full h-0.5 bg-gradient-to-r from-transparent via-primary to-transparent"
        animate={{
          x: ["-100%", "100%"],
          opacity: [0, 1, 0],
        }}
        transition={{
          duration: 3,
          repeat: Infinity,
          ease: "linear",
        }}
      />
    </section>
  );
};

export default HeroSection;
import HeroSectionSimple from "@/components/sections/HeroSectionSimple";
import CategoriesSection from "@/components/sections/CategoriesSection";
import FeaturedProducts from "@/components/sections/FeaturedProducts";
import ShopTemplates from "@/components/sections/ShopTemplates";

const IndexSimple = () => {
  return (
    <div className="min-h-screen">
      <HeroSectionSimple />
      <CategoriesSection />
      <FeaturedProducts />
      <ShopTemplates />
    </div>
  );
};

export default IndexSimple;
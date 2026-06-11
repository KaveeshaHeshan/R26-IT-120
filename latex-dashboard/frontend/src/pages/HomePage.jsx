import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import heroImg from '../assets/ttt.png';
import logoImg from '../assets/logo_transparent.png';

const HomePage = () => {
  return (
    <div className="w-full min-h-screen bg-white font-sans overflow-x-hidden selection:bg-teal-500/30 text-gray-800">
      
      {/* ── NAVBAR ──────────────────────────────────────────────────────── */}
      <nav className="w-full bg-[#0a3622] text-white px-8 py-3 flex items-center justify-between z-50 relative shadow-md">
        <div className="flex items-center gap-2">
           <img 
             src={logoImg} 
             alt="LatexGuard Logo" 
             className="h-12 md:h-16 lg:h-20 w-auto object-contain drop-shadow-md transition-transform hover:scale-105" 
           />
        </div>
        
        <div className="hidden md:flex items-center gap-10 text-sm font-medium tracking-wide">
          <a href="#" className="hover:text-teal-300 transition-colors">HOME</a>
          <a href="#" className="hover:text-teal-300 transition-colors">OUR SENSORS</a>
          <a href="#" className="hover:text-teal-300 transition-colors">ANALYTICS</a>
          <a href="#" className="hover:text-teal-300 transition-colors">SUPPORT</a>
        </div>

        <Link to="/login">
          <button className="bg-[#e9eff1] hover:bg-white text-[#0a3622] px-8 py-2.5 rounded-full text-sm font-bold tracking-wide transition-all shadow-sm">
            LOGIN TO PORTAL
          </button>
        </Link>
      </nav>

      {/* ── HERO SECTION ──────────────────────────────────────────────────────── */}
      <section className="relative w-full min-h-[600px] flex items-center bg-[#fcfdfc] overflow-hidden py-20 lg:py-0">
        
        {/* Background Image */}
        <div className="absolute top-0 left-0 w-full h-full flex">
          <div className="w-full lg:w-[60%] h-full relative opacity-20 lg:opacity-100">
             <img src={heroImg} alt="Factory Worker" className="w-full h-full object-cover object-right lg:object-center" />
             {/* Fade effect so the image blends smoothly into the white right side on desktop, and fades to bottom on mobile */}
             <div className="hidden lg:block absolute top-0 right-0 w-48 h-full bg-gradient-to-r from-transparent to-[#fcfdfc]"></div>
             <div className="block lg:hidden absolute bottom-0 left-0 w-full h-48 bg-gradient-to-t from-[#fcfdfc] to-transparent"></div>
          </div>
          <div className="hidden lg:block w-[40%] h-full bg-[#fcfdfc]"></div>
        </div>

        {/* Content */}
        <div className="relative z-10 w-full h-full flex justify-center lg:justify-end">
          <div className="w-full lg:w-[40%] px-6 md:px-12 xl:px-20 flex flex-col justify-center items-center text-center h-full">
            <motion.h1 
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, ease: "easeOut" }}
              className="text-4xl sm:text-5xl md:text-6xl font-serif font-black text-gray-900 leading-[1.2] mb-8 mt-10 lg:mt-0 drop-shadow-sm lg:drop-shadow-none"
            >
              THE SHIELD <br />
              OF QUALITY <br />
              IN NATURAL <br />
              RUBBER
            </motion.h1>
            
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, ease: "easeOut", delay: 0.2 }}
              className="text-gray-800 lg:text-gray-600 text-base sm:text-lg mb-10 max-w-md leading-relaxed font-medium lg:font-light drop-shadow-sm lg:drop-shadow-none"
            >
              Sustaining industrial excellence with premium, high-durability natural rubber solutions, powered by intelligent, real-time monitoring.
            </motion.p>

            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, ease: "easeOut", delay: 0.4 }}
              className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto"
            >
              <button className="w-full sm:w-auto bg-[#0a3622] hover:bg-[#072618] text-white px-8 py-3.5 rounded-full text-sm font-bold tracking-wide transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5">
                EXPLORE SOLUTIONS
              </button>
              <button className="w-full sm:w-auto bg-white/50 lg:bg-transparent border border-gray-400 hover:border-gray-600 text-gray-800 px-8 py-3.5 rounded-full text-sm font-bold tracking-wide transition-all backdrop-blur-sm lg:backdrop-blur-none">
                LEARN MORE
              </button>
            </motion.div>
          </div>
        </div>
      </section>

      {/* ── FEATURES SECTION ────────────────────────────────────────────────────── */}
      <section className="w-full py-20 bg-white">
        <div className="max-w-7xl mx-auto px-8">
          <h2 className="text-center text-3xl font-bold text-gray-900 mb-14 tracking-wide">
            OUR INTELLIGENT MONITORING
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            
            {/* Card 1 */}
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.6, ease: "easeOut" }}
              className="bg-gradient-to-r from-[#f0f4f4] to-[#f8fafa] rounded-2xl p-8 flex items-center justify-between border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300 cursor-pointer group"
            >
              <h3 className="text-base font-black text-gray-800 uppercase tracking-wider leading-snug max-w-[120px]">
                Real-Time <br/> Tracking
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                📱
              </div>
            </motion.div>

            {/* Card 2 */}
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.6, ease: "easeOut", delay: 0.15 }}
              className="bg-gradient-to-r from-[#f0f4f4] to-[#f8fafa] rounded-2xl p-8 flex items-center justify-between border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300 cursor-pointer group"
            >
              <h3 className="text-base font-black text-gray-800 uppercase tracking-wider leading-snug max-w-[120px]">
                Predictive <br/> Maintenance
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                ⚙️
              </div>
            </motion.div>

            {/* Card 3 */}
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.6, ease: "easeOut", delay: 0.3 }}
              className="bg-gradient-to-r from-[#f0f4f4] to-[#f8fafa] rounded-2xl p-8 flex items-center justify-between border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300 cursor-pointer group"
            >
              <h3 className="text-base font-black text-gray-800 uppercase tracking-wider leading-snug max-w-[120px]">
                Quality <br/> Assurance
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                🎖️
              </div>
            </motion.div>

          </div>
        </div>
      </section>

    </div>
  );
};

export default HomePage;

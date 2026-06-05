import { Link } from 'react-router-dom';
import heroImg from '../assets/ttt.png';
import logoImg from '../assets/logo_transparent.png';

const HomePage = () => {
  return (
    <div className="w-full min-h-screen bg-white font-sans overflow-x-hidden selection:bg-teal-500/30 text-gray-800">
      
      {/* ── NAVBAR ──────────────────────────────────────────────────────── */}
      <nav className="w-full bg-[#0a3622] text-white px-8 py-5 flex items-center justify-between z-50 relative">
        <div className="flex items-center gap-2">
           <img 
             src={logoImg} 
             alt="LatexGuard Logo" 
             className="h-16 md:h-20 lg:h-24 w-auto object-contain drop-shadow-md transition-transform hover:scale-105" 
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
      <section className="relative w-full h-[600px] flex items-center bg-[#fcfdfc] overflow-hidden">
        
        {/* Background Image (Left Aligned) with Gradient Fade to Right */}
        <div className="absolute top-0 left-0 w-full h-full flex">
          <div className="w-[55%] h-full relative">
             <img src={heroImg} alt="Factory Worker" className="w-full h-full object-cover object-right" />
             {/* Fade effect so the image blends smoothly into the white right side */}
             <div className="absolute top-0 right-0 w-48 h-full bg-gradient-to-r from-transparent to-[#fcfdfc]"></div>
          </div>
          <div className="w-[45%] h-full bg-[#fcfdfc]"></div>
        </div>

        {/* Content */}
        <div className="relative z-10 w-full max-w-7xl mx-auto px-8 flex justify-end">
          <div className="w-1/2 pl-12 flex flex-col justify-center">
            <h1 className="text-5xl md:text-6xl font-serif font-black text-gray-900 leading-[1.1] mb-6">
              THE SHIELD OF <br/>
              QUALITY IN <br/>
              NATURAL RUBBER
            </h1>
            
            <p className="text-gray-600 text-lg mb-10 max-w-md leading-relaxed font-light">
              Sustaining industrial excellence with premium, high-durability natural rubber solutions, powered by intelligent, real-time monitoring.
            </p>

            <div className="flex items-center gap-4">
              <button className="bg-[#0a3622] hover:bg-[#072618] text-white px-8 py-3.5 rounded-full text-sm font-bold tracking-wide transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5">
                EXPLORE SOLUTIONS
              </button>
              <button className="bg-transparent border border-gray-300 hover:border-gray-400 text-gray-700 px-8 py-3.5 rounded-full text-sm font-bold tracking-wide transition-all">
                LEARN MORE
              </button>
            </div>
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
            <div className="bg-gradient-to-r from-[#f0f4f4] to-[#f8fafa] rounded-2xl p-8 flex items-center justify-between border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300 cursor-pointer group">
              <h3 className="text-base font-black text-gray-800 uppercase tracking-wider leading-snug max-w-[120px]">
                Real-Time <br/> Tracking
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                📱
              </div>
            </div>

            {/* Card 2 */}
            <div className="bg-gradient-to-r from-[#f0f4f4] to-[#f8fafa] rounded-2xl p-8 flex items-center justify-between border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300 cursor-pointer group">
              <h3 className="text-base font-black text-gray-800 uppercase tracking-wider leading-snug max-w-[120px]">
                Predictive <br/> Maintenance
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                ⚙️
              </div>
            </div>

            {/* Card 3 */}
            <div className="bg-gradient-to-r from-[#f0f4f4] to-[#f8fafa] rounded-2xl p-8 flex items-center justify-between border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300 cursor-pointer group">
              <h3 className="text-base font-black text-gray-800 uppercase tracking-wider leading-snug max-w-[120px]">
                Quality <br/> Assurance
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                🎖️
              </div>
            </div>

          </div>
        </div>
      </section>

    </div>
  );
};

export default HomePage;

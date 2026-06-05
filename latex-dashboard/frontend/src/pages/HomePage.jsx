import { Link } from 'react-router-dom';
import videoBg from '../assets/rubber.mp4';

const HomePage = () => {
  return (
    <div className="w-full min-h-screen bg-[#020e07] text-white font-sans overflow-x-hidden selection:bg-emerald-500/30">
      
      {/* ── HERO SECTION ──────────────────────────────────────────────────────── */}
      <section className="relative w-full h-screen flex flex-col items-center justify-center">
        {/* Video Background */}
        <video
          autoPlay
          loop
          muted
          playsInline
          className="absolute top-0 left-0 w-full h-full object-cover opacity-90"
        >
          <source src={videoBg} type="video/mp4" />
        </video>

        {/* Gradient Overlay for Cinematic Effect - Lightened drastically */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-[#020e07] pointer-events-none"></div>

        {/* Content */}
        <div className="relative z-10 flex flex-col items-center justify-center h-full px-4 text-center mt-12">
          {/* Title */}
          <div className="animate-fade-in-up">
            <h1 className="text-6xl md:text-8xl lg:text-[8rem] font-black tracking-[0.15em] text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-teal-300 to-cyan-500 mb-6 drop-shadow-[0_0_30px_rgba(52,211,153,0.25)]">
              LATEXGUARD
            </h1>
          </div>
          
          {/* Subtitle */}
          <p className="max-w-2xl text-lg md:text-2xl text-gray-400 font-light tracking-wide mb-14 animate-fade-in-up animation-delay-300">
            Intelligent, real-time precision monitoring for premium rubber production.
          </p>

          {/* Action Button */}
          <div className="animate-fade-in-up animation-delay-600">
            <Link to="/login">
              <button className="group relative px-10 py-5 text-sm md:text-base font-bold text-white transition-all duration-500 rounded-full bg-white/5 backdrop-blur-md border border-white/10 hover:bg-white/10 hover:border-emerald-500/50 hover:scale-[1.02] hover:shadow-[0_0_40px_rgba(16,185,129,0.2)] focus:outline-none focus:ring-4 focus:ring-emerald-500/30 overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-r from-emerald-600/20 to-cyan-600/20 opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-full"></div>
                <span className="relative z-10 flex items-center gap-3 tracking-[0.2em]">
                  LOGIN TO PORTAL
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 group-hover:translate-x-1.5 transition-transform duration-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 5l7 7m0 0l-7 7m7-7H3" />
                  </svg>
                </span>
              </button>
            </Link>
          </div>
        </div>

        {/* Scroll Indicator */}
        <div className="absolute bottom-10 left-0 w-full flex justify-center z-10 animate-fade-in animation-delay-1000">
          <div className="flex flex-col items-center gap-4">
            <p className="text-[10px] text-gray-500 tracking-[0.4em] uppercase font-bold">
              Discover Features
            </p>
            <div className="w-[1px] h-16 bg-gradient-to-b from-emerald-500/50 to-transparent animate-pulse"></div>
          </div>
        </div>
      </section>

      {/* ── DETAILS SECTION ────────────────────────────────────────────────────── */}
      <section className="relative w-full py-32 px-6 md:px-12 lg:px-24 bg-[#020e07] z-20">
        
        {/* Decorative Grid Background */}
        <div className="absolute inset-0 opacity-[0.02] bg-[linear-gradient(rgba(255,255,255,1)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,1)_1px,transparent_1px)] bg-[size:40px_40px] pointer-events-none"></div>

        <div className="max-w-7xl mx-auto relative z-10">
          
          <div className="text-center mb-24">
            <h2 className="text-3xl md:text-5xl font-black text-white tracking-tight mb-6">
              Precision <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-cyan-500">Quality Control</span>
            </h2>
            <p className="text-gray-400 text-lg md:text-xl max-w-3xl mx-auto font-light leading-relaxed">
              LatexGuard leverages advanced IoT sensors and machine learning algorithms to monitor the critical parameters of liquid natural rubber in real-time.
            </p>
          </div>

          {/* Feature Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            
            {/* Feature 1 */}
            <div className="group p-10 rounded-[2rem] bg-white/[0.02] border border-white/5 hover:border-emerald-500/30 hover:bg-white/[0.04] transition-all duration-500 backdrop-blur-sm hover:-translate-y-2">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-emerald-500/5 flex items-center justify-center border border-emerald-500/20 mb-8 group-hover:scale-110 group-hover:rotate-3 transition-transform duration-500">
                <span className="text-3xl">🧪</span>
              </div>
              <h3 className="text-2xl font-bold text-white mb-4 tracking-wide">VFA Level Detection</h3>
              <p className="text-gray-400 font-light leading-relaxed text-sm md:text-base">
                Accurately measure Volatile Fatty Acid numbers. Predict early coagulation and ensure the latex meets premium export standards without manual laboratory delays.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="group p-10 rounded-[2rem] bg-white/[0.02] border border-white/5 hover:border-cyan-500/30 hover:bg-white/[0.04] transition-all duration-500 backdrop-blur-sm hover:-translate-y-2">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-cyan-500/20 to-cyan-500/5 flex items-center justify-center border border-cyan-500/20 mb-8 group-hover:scale-110 group-hover:rotate-3 transition-transform duration-500">
                <span className="text-3xl">🌡️</span>
              </div>
              <h3 className="text-2xl font-bold text-white mb-4 tracking-wide">Environmental Tracking</h3>
              <p className="text-gray-400 font-light leading-relaxed text-sm md:text-base">
                Real-time monitoring of pH, turbidity, and ambient temperature. LatexGuard cross-references these parameters to prevent spontaneous degradation.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="group p-10 rounded-[2rem] bg-white/[0.02] border border-white/5 hover:border-teal-500/30 hover:bg-white/[0.04] transition-all duration-500 backdrop-blur-sm hover:-translate-y-2">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-teal-500/20 to-teal-500/5 flex items-center justify-center border border-teal-500/20 mb-8 group-hover:scale-110 group-hover:rotate-3 transition-transform duration-500">
                <span className="text-3xl">🤖</span>
              </div>
              <h3 className="text-2xl font-bold text-white mb-4 tracking-wide">Predictive Analytics</h3>
              <p className="text-gray-400 font-light leading-relaxed text-sm md:text-base">
                Our Random Forest Regression models analyze field data instantly, automatically assigning quality grades (A, B, C) and alerting officers before issues arise.
              </p>
            </div>

          </div>

          {/* CTA Banner */}
          <div className="mt-32 p-12 md:p-16 rounded-[3rem] bg-gradient-to-br from-emerald-900/30 to-transparent border border-emerald-500/20 relative overflow-hidden flex flex-col lg:flex-row items-center justify-between gap-10">
            <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-emerald-500/10 rounded-full blur-[120px] pointer-events-none"></div>
            <div className="relative z-10 text-center lg:text-left">
              <h3 className="text-3xl md:text-4xl font-black text-white mb-4 tracking-tight">Ready to access the dashboard?</h3>
              <p className="text-gray-400 max-w-xl text-lg font-light">Secure login required for plantation managers and QA officers to view live sensor telemetry and intelligent insights.</p>
            </div>
            <Link to="/login" className="relative z-10 shrink-0">
              <button className="px-12 py-5 text-sm md:text-base font-bold text-[#020e07] uppercase tracking-[0.15em] rounded-full bg-emerald-400 hover:bg-emerald-300 transition-colors shadow-[0_0_40px_rgba(52,211,153,0.3)] hover:scale-105 duration-300">
                Initialize Session
              </button>
            </Link>
          </div>

        </div>
      </section>

      {/* ── FOOTER ───────────────────────────────────────────────────────────── */}
      <footer className="py-10 text-center border-t border-white/5 bg-[#020e07]">
        <p className="text-gray-600 text-[10px] md:text-xs tracking-[0.3em] uppercase font-bold flex items-center justify-center gap-2">
          <span>© {new Date().getFullYear()} LatexGuard System</span>
          <span className="text-emerald-500/50">•</span>
          <span>Precision Rubber Monitoring</span>
        </p>
      </footer>

    </div>
  );
};

export default HomePage;

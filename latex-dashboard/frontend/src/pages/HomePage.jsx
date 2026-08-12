import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import heroImg from '../assets/ttt.png';
import logoImg from '../assets/logo_transparent.png';

const HomePage = () => {
  const [pH, setPH] = useState(9.8);
  const [temperature, setTemperature] = useState(28.0);
  const [turbidity, setTurbidity] = useState(120);

  // VFA calculation logic
  const calculateMetrics = () => {
    let simulatedVFA = 0.045 + (10.5 - pH) * 0.05 + (temperature - 28) * 0.002 + (turbidity - 120) * 0.00005;
    simulatedVFA = Math.max(0.01, Math.min(0.15, simulatedVFA));
    
    let grade = 'C';
    if (simulatedVFA < 0.05) grade = 'A';
    else if (simulatedVFA < 0.08) grade = 'B';
    
    return {
      vfa: simulatedVFA.toFixed(4),
      grade
    };
  };

  const { vfa, grade } = calculateMetrics();
  const navigate = useNavigate();

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
              className="text-gray-800 text-base sm:text-lg mb-10 max-w-md leading-relaxed font-bold drop-shadow-sm lg:drop-shadow-none"
            >
              Sustaining industrial excellence with premium, high-durability natural rubber solutions, powered by intelligent, real-time monitoring.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, ease: "easeOut", delay: 0.4 }}
              className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto"
            >
              <button
                onClick={() => navigate('/login')}
                className="w-full sm:w-auto bg-[#0a3622] hover:bg-[#072618] text-white px-8 py-3.5 rounded-full text-sm font-bold tracking-wide transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5">
                EXPLORE SOLUTIONS
              </button>
              <button
                onClick={() => document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })}
                className="w-full sm:w-auto bg-white/50 lg:bg-transparent border border-gray-400 hover:border-gray-600 text-gray-800 px-8 py-3.5 rounded-full text-sm font-bold tracking-wide transition-all backdrop-blur-sm lg:backdrop-blur-none">
                LEARN MORE
              </button>
            </motion.div>
          </div>
        </div>
      </section>

      {/* ── METRICS / HIGHLIGHTS BAR ────────────────────────────────────────── */}
      <div className="relative z-20 -mt-10 max-w-5xl mx-auto px-4">
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut", delay: 0.5 }}
          className="bg-white/90 backdrop-blur-md rounded-3xl shadow-[0_20px_40px_rgba(10,54,34,0.08)] border border-emerald-50/50 p-6 md:p-8 grid grid-cols-2 md:grid-cols-4 gap-6 md:gap-4 text-center"
        >
          {/* Stat 1 */}
          <div className="flex flex-col items-center justify-center p-2 border-b md:border-b-0 md:border-r border-emerald-100/50 pb-6 md:pb-0">
            <div className="text-3xl mb-2 filter drop-shadow-sm">📊</div>
            <div className="text-xl sm:text-2xl font-extrabold text-gray-900 tracking-tight">300+ Samples</div>
            <div className="text-[10px] sm:text-xs font-semibold text-emerald-800/70 uppercase tracking-wider mt-1">Processed</div>
          </div>
          
          {/* Stat 2 */}
          <div className="flex flex-col items-center justify-center p-2 border-b md:border-b-0 md:border-r border-emerald-100/50 pb-6 md:pb-0">
            <div className="text-3xl mb-2 filter drop-shadow-sm">✅</div>
            <div className="text-xl sm:text-2xl font-extrabold text-[#0a3622] tracking-tight">96.9% Grade A</div>
            <div className="text-[10px] sm:text-xs font-semibold text-emerald-800/70 uppercase tracking-wider mt-1">Accuracy & Quality</div>
          </div>

          {/* Stat 3 */}
          <div className="flex flex-col items-center justify-center p-2 border-b md:border-b-0 md:border-r border-emerald-100/50 pb-6 md:pb-0">
            <div className="text-3xl mb-2 filter drop-shadow-sm">⚡</div>
            <div className="text-xl sm:text-2xl font-extrabold text-gray-900 tracking-tight">Real-time</div>
            <div className="text-[10px] sm:text-xs font-semibold text-emerald-800/70 uppercase tracking-wider mt-1">Live Telemetry</div>
          </div>

          {/* Stat 4 */}
          <div className="flex flex-col items-center justify-center p-2 pt-4 md:pt-0">
            <div className="text-3xl mb-2 filter drop-shadow-sm">🌿</div>
            <div className="text-xl sm:text-2xl font-extrabold text-gray-900 tracking-tight">4 Sensors</div>
            <div className="text-[10px] sm:text-xs font-semibold text-emerald-800/70 uppercase tracking-wider mt-1">Environmental Suite</div>
          </div>
        </motion.div>
      </div>

      {/* ── FEATURES SECTION ────────────────────────────────────────────────────── */}
      <section id="features" className="w-full py-20 bg-white">
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
                Real-Time <br /> Tracking
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
                Predictive <br /> Maintenance
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
                Quality <br /> Assurance
              </h3>
              <div className="w-16 h-16 bg-white/60 rounded-2xl shadow-sm border border-white flex items-center justify-center text-3xl group-hover:scale-110 transition-transform">
                🎖️
              </div>
            </motion.div>

          </div>
        </div>
      </section>

      {/* ── INTERACTIVE QUALITY SIMULATOR ──────────────────────────────────────── */}
      <section className="w-full py-20 bg-emerald-50/30 border-y border-emerald-50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            
            {/* Left side: description and sliders */}
            <div>
              <span className="text-emerald-800 font-extrabold text-sm uppercase tracking-wider bg-emerald-100/50 px-4 py-1.5 rounded-full">
                Interactive Sandbox
              </span>
              <h2 className="text-3xl sm:text-4xl font-black text-gray-900 tracking-tight mt-4 mb-6">
                Latex Quality ML Simulator
              </h2>
              <p className="text-gray-600 font-medium leading-relaxed mb-8">
                Adjust the environmental and chemical parameter sliders below to simulate how the LatexGuard Random Forest model evaluates latex volatile fatty acids (VFA) and assigns grades in real-time.
              </p>

              <div className="space-y-6">
                {/* pH Slider */}
                <div>
                  <div className="flex justify-between text-sm font-bold text-gray-800 mb-2">
                    <span>pH Level (Acidity/Alkalinity)</span>
                    <span className="text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded">{pH} pH</span>
                  </div>
                  <input
                    type="range"
                    min="8.0"
                    max="12.0"
                    step="0.1"
                    value={pH}
                    onChange={(e) => setPH(parseFloat(e.target.value))}
                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-[#0a3622]"
                  />
                  <div className="flex justify-between text-[10px] text-gray-400 font-bold mt-1">
                    <span>8.0 (Acidic/Degraded)</span>
                    <span>10.5 (Optimal)</span>
                    <span>12.0 (High Ammonia)</span>
                  </div>
                </div>

                {/* Temperature Slider */}
                <div>
                  <div className="flex justify-between text-sm font-bold text-gray-800 mb-2">
                    <span>Temperature</span>
                    <span className="text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded">{temperature}°C</span>
                  </div>
                  <input
                    type="range"
                    min="20.0"
                    max="45.0"
                    step="0.5"
                    value={temperature}
                    onChange={(e) => setTemperature(parseFloat(e.target.value))}
                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-[#0a3622]"
                  />
                  <div className="flex justify-between text-[10px] text-gray-400 font-bold mt-1">
                    <span>20.0°C</span>
                    <span>28.0°C (Standard Ambient)</span>
                    <span>45.0°C (High Risk)</span>
                  </div>
                </div>

                {/* Turbidity Slider */}
                <div>
                  <div className="flex justify-between text-sm font-bold text-gray-800 mb-2">
                    <span>Turbidity (Latex Density & Purity)</span>
                    <span className="text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded">{turbidity} NTU</span>
                  </div>
                  <input
                    type="range"
                    min="10"
                    max="1000"
                    step="10"
                    value={turbidity}
                    onChange={(e) => setTurbidity(parseInt(e.target.value))}
                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-[#0a3622]"
                  />
                  <div className="flex justify-between text-[10px] text-gray-400 font-bold mt-1">
                    <span>10 NTU (Watery)</span>
                    <span>120 NTU (Ideal Density)</span>
                    <span>1000 NTU (Impure/Coagulating)</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Right side: Real-time Grade Output Display */}
            <div className="bg-white rounded-3xl p-8 border border-emerald-50 shadow-[0_20px_50px_rgba(10,54,34,0.05)] text-center relative overflow-hidden flex flex-col justify-between min-h-[360px]">
              <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-50/50 rounded-full blur-2xl -z-10"></div>
              
              <div>
                <h3 className="text-xs font-black tracking-widest text-emerald-800/80 uppercase mb-6">
                  PREDICTED OUTPUT
                </h3>
                
                <div className="inline-flex items-center justify-center w-28 h-28 rounded-full mb-6 relative">
                  <div className={`absolute inset-0 rounded-full animate-ping opacity-10 ${
                    grade === 'A' ? 'bg-emerald-500' : grade === 'B' ? 'bg-amber-500' : 'bg-red-500'
                  }`}></div>
                  <div className={`w-24 h-24 rounded-full flex flex-col items-center justify-center font-black text-4xl shadow-inner text-white ${
                    grade === 'A' ? 'bg-emerald-600' : grade === 'B' ? 'bg-amber-500' : 'bg-red-600'
                  }`}>
                    {grade}
                  </div>
                </div>

                <div className="text-sm font-extrabold text-gray-500 uppercase tracking-wide">
                  Calculated VFA Level
                </div>
                <div className="text-3xl font-serif font-black text-gray-900 mt-1">
                  {vfa} <span className="text-sm font-sans font-bold text-gray-400">VFA</span>
                </div>
              </div>

              <div className="mt-8 border-t border-gray-100 pt-6">
                <div className="text-xs font-bold text-gray-500 uppercase">Status & Recommendations</div>
                <p className="text-sm font-semibold text-gray-700 mt-2">
                  {grade === 'A' && "🌿 Premium Grade A: Latex is highly stable with minimal acid production. Excellent for industrial manufacturing."}
                  {grade === 'B' && "⚠️ Grade B: Acceptable quality, but showing signs of mild acidification. Recommend processing within 12 hours."}
                  {grade === 'C' && "🚨 Grade C Alert: Critical acidity detected! High VFA concentration. Latex is at risk of premature coagulation."}
                </p>
              </div>

            </div>

          </div>
        </div>
      </section>

      {/* ── QUICK NAVIGATION SECTION ───────────────────────────────────────────── */}
      <section className="w-full py-20 bg-gradient-to-b from-[#fcfdfc] to-[#eef4f2]">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <h2 className="text-3xl font-black text-gray-900 tracking-wide mb-4">
              QUICK NAVIGATION
            </h2>
            <p className="text-gray-600 font-medium">
              Access the secure system dashboards and specialized management tools directly.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            
            {/* Card 1: Live Monitor */}
            <Link to="/dashboard" className="block group">
              <motion.div
                whileHover={{ y: -6, scale: 1.02 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                className="bg-white rounded-3xl p-8 border border-emerald-50 shadow-[0_10px_30px_rgba(0,0,0,0.02)] group-hover:shadow-[0_20px_45px_rgba(10,54,34,0.08)] transition-all h-full flex flex-col justify-between"
              >
                <div>
                  <div className="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:bg-[#0a3622] group-hover:text-white transition-all">
                    📡
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Live Monitor</h3>
                  <p className="text-gray-500 text-sm leading-relaxed mb-6">
                    Real-time sensor streams, device health status, and environment diagnostics.
                  </p>
                </div>
                <div className="flex items-center text-[#0a3622] font-extrabold text-sm group-hover:translate-x-2 transition-transform">
                  Access Portal <span className="ml-2 text-lg">→</span>
                </div>
              </motion.div>
            </Link>

            {/* Card 2: Farmer Profile */}
            <Link to="/farmer" className="block group">
              <motion.div
                whileHover={{ y: -6, scale: 1.02 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                className="bg-white rounded-3xl p-8 border border-emerald-50 shadow-[0_10px_30px_rgba(0,0,0,0.02)] group-hover:shadow-[0_20px_45px_rgba(10,54,34,0.08)] transition-all h-full flex flex-col justify-between"
              >
                <div>
                  <div className="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:bg-[#0a3622] group-hover:text-white transition-all">
                    👨‍🌾
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Farmer Profile</h3>
                  <p className="text-gray-500 text-sm leading-relaxed mb-6">
                    Manage farmer directory, yield records, payouts, and compliance logs.
                  </p>
                </div>
                <div className="flex items-center text-[#0a3622] font-extrabold text-sm group-hover:translate-x-2 transition-transform">
                  Access Profiles <span className="ml-2 text-lg">→</span>
                </div>
              </motion.div>
            </Link>

            {/* Card 3: Alerts */}
            <Link to="/alerts" className="block group">
              <motion.div
                whileHover={{ y: -6, scale: 1.02 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                className="bg-white rounded-3xl p-8 border border-emerald-50 shadow-[0_10px_30px_rgba(0,0,0,0.02)] group-hover:shadow-[0_20px_45px_rgba(10,54,34,0.08)] transition-all h-full flex flex-col justify-between"
              >
                <div>
                  <div className="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:bg-[#0a3622] group-hover:text-white transition-all">
                    🔔
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Alerts</h3>
                  <p className="text-gray-500 text-sm leading-relaxed mb-6">
                    Critical warning logs, anomaly notifications, and thresholds triggers.
                  </p>
                </div>
                <div className="flex items-center text-[#0a3622] font-extrabold text-sm group-hover:translate-x-2 transition-transform">
                  View Alerts <span className="ml-2 text-lg">→</span>
                </div>
              </motion.div>
            </Link>

            {/* Card 4: Daily Summary */}
            <Link to="/summary" className="block group">
              <motion.div
                whileHover={{ y: -6, scale: 1.02 }}
                transition={{ type: "spring", stiffness: 300, damping: 20 }}
                className="bg-white rounded-3xl p-8 border border-emerald-50 shadow-[0_10px_30px_rgba(0,0,0,0.02)] group-hover:shadow-[0_20px_45px_rgba(10,54,34,0.08)] transition-all h-full flex flex-col justify-between"
              >
                <div>
                  <div className="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:bg-[#0a3622] group-hover:text-white transition-all">
                    📊
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Daily Summary</h3>
                  <p className="text-gray-500 text-sm leading-relaxed mb-6">
                    Daily analytics breakdown, aggregate yield KPIs, and quality scores reports.
                  </p>
                </div>
                <div className="flex items-center text-[#0a3622] font-extrabold text-sm group-hover:translate-x-2 transition-transform">
                  View Summaries <span className="ml-2 text-lg">→</span>
                </div>
              </motion.div>
            </Link>

          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS SECTION ─────────────────────────────────────────────── */}
      <section className="w-full py-20 bg-white">
        <div className="max-w-7xl mx-auto px-8 text-center">
          <span className="text-emerald-800 font-extrabold text-sm uppercase tracking-wider bg-emerald-100/50 px-4 py-1.5 rounded-full">
            Technical Architecture
          </span>
          <h2 className="text-3xl sm:text-4xl font-black text-gray-900 tracking-wide mt-4 mb-14">
            How LatexGuard Safeguards Quality
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            
            {/* Step 1 */}
            <div className="relative">
              <div className="w-16 h-16 bg-[#0a3622] text-white rounded-2xl flex items-center justify-center font-bold text-2xl mx-auto mb-6 shadow-md">
                1
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">IoT Smart Sensors</h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                Submersible node captures pH, Temperature, Turbidity, and ambient variables directly from collecting cups.
              </p>
            </div>

            {/* Step 2 */}
            <div className="relative">
              <div className="w-16 h-16 bg-[#0a3622] text-white rounded-2xl flex items-center justify-center font-bold text-2xl mx-auto mb-6 shadow-md">
                2
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">Telemetry Pipeline</h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                Sensor data is uploaded via cellular/LoRaWAN gateway in real-time to the cloud database.
              </p>
            </div>

            {/* Step 3 */}
            <div className="relative">
              <div className="w-16 h-16 bg-[#0a3622] text-white rounded-2xl flex items-center justify-center font-bold text-2xl mx-auto mb-6 shadow-md">
                3
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">RF Model Evaluation</h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                Random Forest machine learning algorithms compute Volatile Fatty Acid (VFA) content to classify latex quality.
              </p>
            </div>

            {/* Step 4 */}
            <div className="relative">
              <div className="w-16 h-16 bg-[#0a3622] text-white rounded-2xl flex items-center justify-center font-bold text-2xl mx-auto mb-6 shadow-md">
                4
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">Instant Alerts & Action</h3>
              <p className="text-gray-500 text-sm leading-relaxed">
                If degradation is detected, automated alerts notify administrators immediately to initiate stabilization.
              </p>
            </div>

          </div>
        </div>
      </section>

      {/* ── SYSTEM STATUS SECTION ────────────────────────────────────────────── */}
      <section className="w-full py-16 bg-[#0a3622] text-white border-t border-emerald-900/60">
        <div className="max-w-7xl mx-auto px-8">
          <div className="flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="max-w-md text-center lg:text-left">
              <h2 className="text-2xl font-black tracking-wide mb-2 uppercase">
                System Status
              </h2>
              <p className="text-emerald-100/70 text-sm leading-relaxed font-semibold">
                Live operational health and connection status of core LatexGuard services.
              </p>
            </div>
            
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 w-full lg:w-auto flex-1 max-w-3xl">
              
              {/* Item 1: IoT Device */}
              <div className="bg-[#0f442d] border border-emerald-800/40 rounded-2xl p-4 flex items-center gap-3">
                <span className="relative flex h-3.5 w-3.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
                </span>
                <div>
                  <div className="text-[10px] text-emerald-300/60 font-bold uppercase tracking-wider">IoT Device</div>
                  <div className="text-sm font-bold text-white">Online</div>
                </div>
              </div>

              {/* Item 2: ML Model */}
              <div className="bg-[#0f442d] border border-emerald-800/40 rounded-2xl p-4 flex items-center gap-3">
                <span className="relative flex h-3.5 w-3.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
                </span>
                <div>
                  <div className="text-[10px] text-emerald-300/60 font-bold uppercase tracking-wider">ML Model</div>
                  <div className="text-sm font-bold text-white">Running</div>
                </div>
              </div>

              {/* Item 3: Firebase */}
              <div className="bg-[#0f442d] border border-emerald-800/40 rounded-2xl p-4 flex items-center gap-3">
                <span className="relative flex h-3.5 w-3.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
                </span>
                <div>
                  <div className="text-[10px] text-emerald-300/60 font-bold uppercase tracking-wider">Firebase</div>
                  <div className="text-sm font-bold text-white">Connected</div>
                </div>
              </div>

              {/* Item 4: API */}
              <div className="bg-[#0f442d] border border-emerald-800/40 rounded-2xl p-4 flex items-center gap-3">
                <span className="relative flex h-3.5 w-3.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3.5 w-3.5 bg-emerald-500"></span>
                </span>
                <div>
                  <div className="text-[10px] text-emerald-300/60 font-bold uppercase tracking-wider">API</div>
                  <div className="text-sm font-bold text-white">Running</div>
                </div>
              </div>

            </div>
          </div>
        </div>
      </section>

      {/* ── FOOTER ───────────────────────────────────────────────────────────── */}
      <footer className="w-full bg-[#051c11] text-emerald-100/50 py-12 px-8 border-t border-emerald-950">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2">
            <img src={logoImg} alt="LatexGuard Logo" className="h-10 opacity-80" />
          </div>
          
          <div className="flex gap-8 text-sm">
            <a href="#" className="hover:text-white transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-white transition-colors">Terms of Service</a>
            <a href="#" className="hover:text-white transition-colors">Documentation</a>
            <a href="#" className="hover:text-white transition-colors">Support Contact</a>
          </div>

          <div className="text-xs font-semibold">
            © {new Date().getFullYear()} LatexGuard. All rights reserved. Industrial Quality Assurance.
          </div>
        </div>
      </footer>

    </div>
  );
};

export default HomePage;

# Chapter 2 "Sand": fact check (research for Milestone 4)

Gathered on 2026-11-27 for the Milestone 4 plan. The session's network rules blocked direct page reads (computerhistory.org, nobelprize.org, onsemi.com and other vendors), so the values come from web-search extracts of the cited URLs, cross-checked against standard references. Nothing here is on screen yet: each value gets checked again when its lesson is written.

Tags:
- **[V]** the value appears in an extract of the cited primary or official source.
- **[P]** partly seen: a secondary copy, a garbled table, or only some of the values.
- **[D]** derived by arithmetic from cited inputs.
- **[U]** unverified.

Hosts that would allow reading the originals: www.computerhistory.org, www.nobelprize.org, www.onsemi.com, www.vishay.com, www.ti.com, assets.nexperia.com, www.diodes.com, irds.ieee.org, nvlpubs.nist.gov, ethw.org.

## 1. Sand to silicon

- **Quartz sand is heated with carbon, which carries the oxygen away as CO gas.** SiO₂ + 2C → Si + 2CO. Brown et al., LibreTexts §12.4.2 "Silicon Devices" [V].
- **The hottest zone reaches about 2000 °C.** NREL report (FY25, OSTI 89464), https://nrel.gov/docs/fy25osti/89464.pdf [V]; Barron, LibreTexts §7.10 [V].
- **Carbon electrodes carry the arc current**: prebaked carbon or graphite on three-phase AC; silicon makers avoid steel-cased self-baking (Söderberg) electrodes because they add iron. Elkem, "Prebaked electrodes"; patent EP0979596B1 [V].
- **Metallurgical-grade silicon is about 98–99 % pure** (">98 %"). NREL 89464 [V].
- **The furnace uses about 12 kWh of electricity per kg of silicon** (11–13 kWh/kg). NREL 89464 [V].
- **Silicon and HCl make liquid trichlorosilane, which is distilled.** Si + 3HCl → SiHCl₃ + H₂ in a fluidized bed. Wacker polysilicon page [V]; 280–400 °C from patents [P].
- **Siemens process:** SiHCl₃ + H₂ → Si + 3HCl, deposited on electrically heated thin silicon rods at about 1100 °C. Quoted rod temperatures: about 1000 °C (Wacker), 1050–1100 °C (patents), 1150 °C (H. Föll, Univ. Kiel) [P].
- **Deposition uses roughly 50–100 kWh per kg**; published figures run from 45 to 200 kWh/kg [P].
- **Chip silicon is 9 to 11 nines pure**: 9N = 99.9999999 % = 1 part per billion atoms; 11N = 0.01 ppba [D]. Wacker's best measured donors plus acceptors: 9 parts per trillion, about 11N; the nines count dopants, not carbon, oxygen or metals. Bernreuter Research (2025), "A silicon purity of 12N only exists in the world of marketers" [V].

## 2. Grow a crystal

- **Silicon melts at 1414 °C** (1687 K). CRC Handbook value, via a page citing it [P]; older texts give 1410–1415 °C.
- **The melt sits in a fused-silica (quartz) crucible in a graphite holder, under argon.** H. Föll, *Electronic Materials* (Univ. Kiel); US 5,902,394 [V].
- **The seed is pulled up at about 1 mm per minute**: body 0.45–1.0 mm/min (one example averaged 0.65); neck 1.5–6 mm/min. EP0823497A1; US 11,408,090 [P].
- **Pull faster, or run the melt hotter, and the crystal gets thinner.** A pull-rate change acts in seconds; a heater change takes tens of minutes. US 6,726,764 [V].
- **Seed and crucible spin opposite ways**: seed about 5–30 rpm (often 8–15), crucible about 5–14 rpm; recipes are trade secrets. Patents; Föll [P].
- **Dash necking:** a thin neck (2–5 mm, about 3 mm) pulled fast first lets dislocations grow out, so the crystal is dislocation-free. W. C. Dash, "Growth of Silicon Crystals Free from Dislocations," J. Appl. Phys. 30, 459–474 (1959), doi:10.1063/1.1702390 [V].
- **A 300 mm ingot is 1–2 m long and weighs a few hundred kilograms.** π(15 cm)² × 2.329 g/cm³ = 1.65 kg per cm, 165 kg per metre [D]; US 6,056,818 gives 200–300 kg [P]; Fraunhofer CSP's research puller makes up to 180 kg [V].
- **Wafer thickness:** 300 mm wafers 775 ± 25 µm; 200 mm 725 µm; 150 mm 675 µm. SEMI M1 (M1-0924, paywalled, not read); values from a vendor sheet and Wikipedia [P].
- **Czochralski, 1916:** the story goes that he dipped his pen into molten tin instead of ink and drew out a thin single-crystal thread. Z. phys. Chem. 92, 219–221 (1918), received 19 August 1916. Tomaszewski & Cahn, MRS Bulletin 29, 348–349 (2004), doi:10.1557/mrs2004.105 [V]; IEEE Milestone #205 (2019), ethw.org/Milestones:Czochralski_Process,_1916 [V]. Present it as a story; versions differ.

## 3. Doping

- **Phosphorus has 5 outer electrons (one spare: N-type); boron has 3 (a hole: P-type).** Standard textbook physics [U page].
- **Silicon has about 5 × 10²² atoms per cm³**: 8/a³ = 8/(5.431 × 10⁻⁸ cm)³ = 4.99 × 10²² [D]; PVEducation 5 × 10²² [V].
- **Pure silicon at 300 K has about 10¹⁰ free electrons per cm³**: n_i = 9.65 × 10⁹ (Altermatt et al., J. Appl. Phys. 93, 1598 (2003)) or 1.00 × 10¹⁰ (Sproul & Green, J. Appl. Phys. 70, 846 (1991)) [V]. Avoid the old 1.45 × 10¹⁰.
- **Pure silicon's resistivity is about 3 × 10⁵ Ω·cm** (3.2 × 10⁵): Ioffe database [V]; check 1/(q·n_i·(µn+µp)) = 3.4 × 10⁵ [D].
- **At 10¹⁵ cm⁻³ one atom in 50 million is a dopant** (4.99 × 10²² / 10¹⁵ = 5.0 × 10⁷) [D].
- **Resistivity at 23 °C** [D, by inverting ASTM F723 / NBS SP 400-64 (Thurber et al., 1981, doi:10.6028/NBS.SP.400-64), now SEMI MF723; self-consistency 3 % boron, 4.5 % phosphorus]:

  | Dopant | 10¹⁵ cm⁻³ | 10¹⁶ cm⁻³ |
  |---|---|---|
  | Phosphorus | 4.5 Ω·cm | 0.52 Ω·cm |
  | Boron | 13.4 Ω·cm | 1.43 Ω·cm |

- **Electrons move about three times more easily than holes**: at 10¹⁵ cm⁻³, µn ≈ 1380, µp ≈ 470 cm²/V·s [D].
- **A bar for the measuring lesson**, 10 mm long and 1 mm × 1 mm, so R = ρ × 100 cm⁻¹ [D]:

  | Sample | Resistance |
  |---|---|
  | Undoped | about 32 MΩ (roughly halves for every ~9 °C of warming) |
  | Phosphorus 10¹⁵ | 450 Ω |
  | Boron 10¹⁵ | 1.3 kΩ |
  | Phosphorus 10¹⁶ | 52 Ω |
  | Boron 10¹⁶ | 140 Ω |

## 4. The diode

- **Where P meets N, electrons fill nearby holes, leaving a depletion region with a built-in voltage.** Sze & Lee, *Physics of Semiconductor Devices*, 3rd ed. (2012), ch. "p–n Junction" [U page].
- **A small silicon diode conducts well from about 0.6–0.7 V**: 0.62–0.72 V at 5 mA (1N4448/1N914B). onsemi 1N914/D [P].
- **1N4001** (onsemi 1N4001/D Rev. 17, November 2021) [V]: V_RRM 50 V; I_O 1.0 A at T_A = 75 °C; I_FSM 30 A (one 60 Hz cycle); V_F 0.93 V typ, 1.1 V max at 1.0 A, T_J = 25 °C. Vishay doc 88503 agrees on 1.1 V and 30 A [V].
- **At 10–20 mA a 1N4001 drops about 0.7 V** [U: the typical curve wasn't readable].
- **The 1N4148 is too small for battery protection**: 100 V, ≤ 1.0 V at 10 mA. Vishay doc 81857 Rev. 1.6 (2024) [P].
- **A red LED needs about 2 V because its material's band gap is wider than silicon's**: 1239.8 eV·nm / 620 nm = 2.0 eV against 1.12 eV for silicon (Ioffe) [V/D]; Vishay TLHR5400: V_F 2.0 V typ at 20 mA [P].
- **Russell Ohl discovered the PN junction at Bell Labs on 23 February 1940**, in silicon whose two regions held different impurities; he showed it to Mervin Kelly on 6 March. CHM Silicon Engine "1940: Discovery of the p-n Junction" [V]; the 6 March date via Riordan & Hoddeson, *Crystal Fire* (1997) [P].

## 5. NMOS: 2N7000

onsemi "2N7000 / 2N7002 / NDS7002A N-Channel Enhancement Mode Field Effect Transistor", NDS7002A/D Rev. 11 (March 2025):
- V_DS max 60 V [V]; V_GS ±20 V (±40 V non-repetitive; the pulse limit reads 50 µs or "50 ms", check) [P].
- I_D 200 mA continuous, 500 mA pulsed; 400 mW [P].
- V_GS(th) 0.8 / 2.1 / 3.0 V (min/typ/max) at V_DS = V_GS, I_D = 1 mA [V].
- R_DS(on) at V_GS = 10 V, I_D = 500 mA: 1.2 Ω typ, 5 Ω max [V].
- R_DS(on) at V_GS = 4.5 V, I_D = 75 mA: 1.8 Ω typ, 5.3 Ω max (Fairchild copies) [V/P].
- C_iss 20/50 pF, C_oss 11/25 pF, C_rss 4/5 pF (typ/max) at V_DS = 25 V, 1 MHz [V].
- **A floating gate is a tiny insulated capacitor**: 20 pF × 2.1 V = 42 pC, about 2.6 × 10⁸ electrons, reaches the typical threshold [D]. TI SCBA004 "Implications of Slow or Floating CMOS Inputs" (Rev. E, 2021) [P]. The fix is a pull-down resistor.
- **Atalla and Kahng made the first working MOSFET at Bell Labs in 1959 and presented it in 1960.** CHM "1960: MOS Transistor Demonstrated" [V]. Kahng's patent US 3,102,230 "Electric Field Controlled Semiconductor Device", filed 31 May 1960 [V].

## 6. PMOS: BS250

- **Vishay BS250** (TO-92), doc 70209 Rev. H (5 July 2004) [V/P]: V(BR)DSS −45 V; V_GS(th) −1 to −3.5 V; r_DS(on) ≤ 14 Ω at V_GS = −10 V; I_D −0.18 A.
- **Diodes Inc. (Zetex) BS250P** (E-Line), Issue 2 (September 1993) [P]: V_DS −45 V; I_D −230 mA; 700 mW; R_DS(on) ≤ 14 Ω at −10 V, −200 mA; V_GS(th) max −3.5 V at −1 mA; C_iss 60 pF.
- **Neither gives R_DS(on) at −4.5 or −5 V**; a worst-case part is only weakly on at 5 V. Alternatives with lower thresholds: Vishay TP0610L (V_GS(th) −1 to −2.4 V) [P].

## 7. The NOT gate (CMOS inverter)

- **CMOS: Frank Wanlass and Chih-Tang Sah, Fairchild, 1963.** "Nanowatt Logic Using Field-Effect Metal-Oxide Semiconductor Triodes," ISSCC Digest, 20 February 1963, pp. 32–33. Patent US 3,356,858 "Low Stand-By Power Complementary Field Effect Circuitry", filed 18 June 1963, granted 5 December 1967, Wanlass sole inventor. CHM "1963: Complementary MOS Circuit Configuration is Invented" [V].
- **Transfer curve:** the output stays at V_DD, drops steeply near the middle, then sits at 0 V. Below V_tn the NMOS is off; above V_DD − |V_tp| the PMOS is off. Rabaey et al., *Digital Integrated Circuits*, 2nd ed. (2003), ch. 5; Weste & Harris, *CMOS VLSI Design*, 4th ed. (2011), §2.5 [P].
- **Switching point** V_M = (V_tn + r(V_DD − |V_tp|))/(1 + r), r = √(k_p/k_n); matched, V_M = V_DD/2. The PMOS is made 2–3× wider because holes are slower [P].
- **Shoot-through:** both transistors partly on for V_tn < V_in < V_DD − |V_tp| [P].
- **SN74HC04 at V_CC = 4.5 V** (TI SCLS078H, April 2021): V_IH min 3.15 V; V_IL max 1.35 V [V]; V_OH min 4.4 V at −20 µA [V]; V_OH min 3.98 V at −4 mA, 25 °C [P]; V_OL max 0.1 V at 20 µA [V]; V_OL max 0.26 V at 4 mA, 25 °C [P].
- **Nexperia 74HC_HCT04 Rev. 10** (16 February 2024): V_OH min 3.98 V, typ 4.32 V at −4 mA, V_CC = 4.5 V [V].
- The 74HC04 is buffered (sharper curve); a single PMOS/NMOS pair matches the unbuffered 74HCU04 [P].

## 8. Your first chip

- **DIP pins are 2.54 mm apart; the rows 7.62 mm apart** (lead centres; JEDEC MS-001). Analog Devices N-14; onsemi case 646-06 [V].
- **Pin 1 is beside the notch or dot; pins count anticlockwise from above** [P].
- **The 74HC04 holds six NOT gates; V_CC on pin 14, GND on pin 7**; supply 2–6 V. TI SCLS078H [V].
- **Jack Kilby, Texas Instruments, 12 September 1958**: a phase-shift oscillator on a germanium bar, gold "flying wires". CHM "1958: All Semiconductor 'Solid Circuit' is Demonstrated"; IEEE Milestone [V]. Patent US 3,138,743, filed 6 February 1959 [V].
- **Robert Noyce, Fairchild, 1959: the planar integrated circuit.** US 2,981,877 "Semiconductor Device-and-Lead Structure", filed 30 July 1959, granted 25 April 1961; built on Hoerni's planar process (US 3,025,589); the first planar IC worked in May 1960. CHM 1959 and 1960 entries [V].
- **Kilby shared the 2000 Nobel Prize in Physics** ("for his part in the invention of the integrated circuit"). nobelprize.org/prizes/physics/2000/summary [V].

## 9. Inside your chip

- **Silicon's lattice constant is 0.543 nm**: a = 5.431 020 511(89) × 10⁻¹⁰ m at 22.5 °C. NIST CODATA 2018 [V].
- **Neighbouring silicon atoms are 0.235 nm apart**: (√3/4)·a = 0.2352 nm [D].
- **Dopant spacing** n^(−1/3) [D]: 10¹⁵ cm⁻³ → 100 nm (about 184 lattice cubes); 10¹⁶ → 46 nm; 10¹⁸ → 10 nm (about 18).
- **Early-1970s chips had features about 10 µm wide**: Intel 4004 (1971), 10 µm, 2,300 transistors. Intel museum page [V].
- **"3 nm" is a name, not a size**: IRDS 2022 gives the 2022 "3 nm" node as G48M24 (48 nm contacted gate pitch, 24 nm metal pitch). irds.ieee.org 2022 Lithography chapter [V]. Physical gate length about 16 nm [P].
- **Bardeen and Brattain's point-contact transistor first amplified on 16 December 1947, demonstrated 23 December.** CHM "1947: Invention of the Point-Contact Transistor"; IEEE Milestone [V].
- **Shockley conceived the junction transistor on 23 January 1948; Teal and Sparks built one in 1950; announced 4 July 1951.** CHM 1948 and 1951 entries [V].
- **1956 Nobel Prize in Physics: Shockley, Bardeen and Brattain** "for their researches on semiconductors and their discovery of the transistor effect." nobelprize.org [V].

## Era check

The design's banner says 1947–1960. Inside it: the transistor (1947), the junction transistor (1948–51), Teal and Little's Czochralski-grown germanium (1950), the 1956 Nobel, Kilby (1958), Dash, Hoerni and Noyce (1959), the MOSFET (1959–60), the first planar IC (1960). Outside it: Czochralski (1916), Ohl (1940), CMOS (1963), the 74HC family (1982), the Intel 4004 (1971), IRDS 2022 and today's parts. Either widen the banner or mark those as "before" and "after".

## Least sure (check before use)

1. The 1N4001's forward voltage at 10–20 mA (about 0.7 V; the curve wasn't readable).
2. The BS250 at |V_GS| = 5 V (not specified), and the BS250P threshold minimum.
3. The 2N7000's non-repetitive V_GS pulse limit, and its 4.5 V row in Rev. 11.
4. The boron conversion constants (boron resistivities ±3 %).
5. IRDS 2022 gate length (16 nm).
6. The Siemens rod temperature (900–1150 °C) and kWh per kg (45–200).
7. The 300 mm ingot mass, and SEMI M1's tolerances.
8. The Atalla–Kahng month and venue, and the grant date of Kahng's patent.
9. The pen-in-tin story (an anecdote, possibly legend).
10. The TLHR5400's 3.0 V maximum forward voltage.

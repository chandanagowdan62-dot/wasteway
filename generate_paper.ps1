$code = @'
using System;
using System.IO;
using System.Reflection;

public class PaperGenerator {
    public static int GeneratePaper(string docxPath, string pdfPath, string imgPath, float bodySize, float paraSpacing, float topMargin, float bottomMargin, float imgHeight, float refSize) {
        Type wordType = Type.GetTypeFromProgID("Word.Application");
        dynamic word = Activator.CreateInstance(wordType);
        try {
            word.Visible = false;
            dynamic doc = word.Documents.Add();
            
            // Set Page Setup to A4
            dynamic pageSetup = doc.PageSetup;
            pageSetup.PaperSize = 7; // wdPaperA4
            pageSetup.TopMargin = topMargin;
            pageSetup.BottomMargin = bottomMargin;
            pageSetup.LeftMargin = 45f;
            pageSetup.RightMargin = 45f;
            
            // Header / Footer
            dynamic primaryFooter = doc.Sections[1].Footers[1]; // wdHeaderFooterPrimary
            primaryFooter.PageNumbers.Add(1, true); // Alignment Center = 1
            
            dynamic sel = word.Selection;
            
            // --- TITLE BLOCK (1 Column) ---
            sel.ParagraphFormat.Alignment = 1; // Center
            sel.ParagraphFormat.SpaceBefore = 0;
            sel.ParagraphFormat.SpaceAfter = 5;
            sel.Font.Name = "Times New Roman";
            sel.Font.Size = 16f;
            sel.Font.Bold = 1;
            sel.TypeText("WasteWay: An AI-Powered Digital Waste Passport and Circularity Guidance System\n");
            
            // Authors
            sel.Font.Size = 10.5f;
            sel.Font.Bold = 1;
            sel.ParagraphFormat.SpaceAfter = 2;
            sel.TypeText("Chandana Gowda N,  Amrutha K,  Athmeeya B S\n");
            
            // Affiliation
            sel.Font.Size = 9.2f;
            sel.Font.Bold = 0;
            sel.Font.Italic = 1;
            sel.ParagraphFormat.SpaceAfter = 9;
            sel.TypeText("Department of Computer Science and Engineering, HKBK College of Engineering, Bengaluru, India\nAcademic Year 2026–2027 | 5th Semester Mini Project | Domain: AI/ML & Environment\n");
            
            // Abstract Box
            sel.ParagraphFormat.Alignment = 3; // Justify
            sel.ParagraphFormat.LeftIndent = 16f;
            sel.ParagraphFormat.RightIndent = 16f;
            sel.ParagraphFormat.SpaceBefore = 3;
            sel.ParagraphFormat.SpaceAfter = 3;
            sel.Font.Size = 9.2f;
            sel.Font.Italic = 0;
            sel.Font.Bold = 1;
            sel.TypeText("Abstract—");
            sel.Font.Bold = 0;
            sel.Font.Italic = 1;
            sel.TypeText("Municipal solid waste management represents a critical environmental and civic operational challenge worldwide, particularly in rapidly urbanizing developing economies. A major systemic failure occurs not during physical landfill collection, but at the household decision-making stage: citizens recognize an item as waste, yet lack immediate material-specific guidance regarding whether it can be reused, repaired, recycled, composted, or safely handed over to authorized collection channels. This paper presents WasteWay, an integrated cross-platform software system that bridges the gap between visual waste identification and actionable circularity pathways. WasteWay incorporates a hybrid artificial intelligence classification pipeline utilizing Google Gemini 3.8 Flash multimodal vision complemented by a fail-safe offline fallback taxonomy encompassing 100 municipal waste items across 10 classes. Upon classification, the system automatically synthesizes an immutable Digital Waste Passport (DWP)—recording Resin Identification Codes (RIC 1–7), material composition percentages, recyclability grades (A through E), biodegradation timelines, and embodied carbon metrics. Grounded in the Seven Rs of the circular economy (Refuse, Reduce, Reuse, Repurpose, Repair, Recycle, Recover), WasteWay delivers tailored handling instructions and routes recyclable streams to a directory of verified localized recycling facilities and digital scrap aggregators in Bengaluru using Haversine proximity calculations without engaging in physical logistics. Furthermore, a strictly segregated Civic Alert workflow enables citizens to capture and submit photographic evidence of public space neglect and illegal dumping with municipal authority grievance guidance. Comprehensive empirical evaluation across 135 automated unit, widget, and integration tests, alongside a 36-sample benchmark evaluation, demonstrates an overall classification accuracy of 83.3% (30/36), a macro precision of 90.9%, a macro recall of 81.8%, a macro F1-score of 81.6%, and 100% negative rejection resilience against non-waste distractors.\n");
            
            // Keywords
            sel.ParagraphFormat.SpaceBefore = 2;
            sel.ParagraphFormat.SpaceAfter = 10;
            sel.Font.Bold = 1;
            sel.Font.Italic = 0;
            sel.TypeText("Keywords—");
            sel.Font.Bold = 0;
            sel.Font.Italic = 1;
            sel.TypeText("Artificial Intelligence, Waste Classification, Digital Waste Passport, Circular Economy, Circularity Guidance, Sustainable Waste Management.\n");
            
            // Reset indents
            sel.ParagraphFormat.LeftIndent = 0;
            sel.ParagraphFormat.RightIndent = 0;
            
            // --- SECTION BREAK FOR 2 COLUMNS ---
            dynamic range = sel.Range;
            dynamic sec2 = doc.Sections.Add(range);
            sec2.PageSetup.TextColumns.SetCount(2);
            sec2.PageSetup.TextColumns.Spacing = 16f;
            
            // Function to add main heading
            Action<string> AddHeading1 = (title) => {
                sel.ParagraphFormat.Alignment = 1; // Center
                sel.ParagraphFormat.SpaceBefore = 7;
                sel.ParagraphFormat.SpaceAfter = 2.5f;
                sel.ParagraphFormat.KeepWithNext = -1;
                sel.Font.Name = "Times New Roman";
                sel.Font.Size = 10.5f;
                sel.Font.Bold = 1;
                sel.Font.Italic = 0;
                sel.TypeText(title + "\n");
            };
            
            // Function to add subsection heading
            Action<string> AddHeading2 = (title) => {
                sel.ParagraphFormat.Alignment = 0; // Left
                sel.ParagraphFormat.SpaceBefore = 5;
                sel.ParagraphFormat.SpaceAfter = 1.5f;
                sel.ParagraphFormat.KeepWithNext = -1;
                sel.Font.Name = "Times New Roman";
                sel.Font.Size = 9.8f;
                sel.Font.Bold = 1;
                sel.Font.Italic = 1;
                sel.TypeText(title + "\n");
            };
            
            // Function to add body paragraph
            Action<string> AddPara = (text) => {
                sel.ParagraphFormat.Alignment = 3; // Justify
                sel.ParagraphFormat.SpaceBefore = 0;
                sel.ParagraphFormat.SpaceAfter = paraSpacing;
                sel.ParagraphFormat.LineSpacingRule = 0; // Single
                sel.Font.Name = "Times New Roman";
                sel.Font.Size = bodySize;
                sel.Font.Bold = 0;
                sel.Font.Italic = 0;
                sel.TypeText(text + "\n");
            };
            
            // Function to add bullet item
            Action<string, string> AddBullet = (prefix, body) => {
                sel.ParagraphFormat.Alignment = 3; // Justify
                sel.ParagraphFormat.SpaceBefore = 0;
                sel.ParagraphFormat.SpaceAfter = 1.5f;
                sel.ParagraphFormat.LeftIndent = 9f;
                sel.Font.Name = "Times New Roman";
                sel.Font.Size = bodySize - 0.3f;
                sel.Font.Bold = 1;
                sel.Font.Italic = 0;
                sel.TypeText(prefix + " ");
                sel.Font.Bold = 0;
                sel.TypeText(body + "\n");
                sel.ParagraphFormat.LeftIndent = 0f;
            };

            // ==================== SECTION I ====================
            AddHeading1("I. INTRODUCTION");
            AddPara("Municipal solid waste management has emerged as one of the most formidable ecological, public health, and infrastructural challenges facing contemporary urban ecosystems. Rapid demographic growth, uncontrolled urbanization, and shifting consumption paradigms have catalyzed an unprecedented proliferation of complex post-consumer waste streams. In developing economies such as India, municipal authorities generate tens of thousands of metric tons of solid waste daily, yet segregation efficiency at source remains persistently inadequate. Consequently, high-value recyclable polymers, metals, and uncontaminated paper fibers are routinely commingled with wet organic food remnants and hazardous household effluents, resulting in catastrophic landfill overburden, open dump fires, and toxic leachate contamination of subterranean aquifers.");
            
            AddPara("A critical, often overlooked operational impediment in solid waste management is that disposal is fundamentally an information and decision-making challenge rather than merely a logistical collection deficit. While householders frequently recognize that an object has reached the end of its initial utility, they lack immediate, scientifically valid guidance on how that material should be sorted, prepared, and directed. Municipal recycling labels and Resin Identification Codes (RICs 1 through 7) are typically microscopic, cryptic, or obscured by product labeling, leading well-intentioned citizens to commit widespread 'wish-cycling'—the erroneous deposition of non-recyclable composite laminates into dry recyclable streams—or conversely, discarding recoverable commodities into unsegregated municipal refuse bins.");
            
            AddHeading2("A. Problem Statement");
            AddPara("Conventional computer vision approaches to waste management remain predominantly confined to automated sorting conveyor belts or isolated laboratory image classifiers. These systems predict a single category label (e.g., 'plastic' or 'paper') but leave the citizen completely unguided regarding material preparation (washing, label removal, drying), circularity options (repairing, repurposing, home composting), and verified geographic drop-off destinations. The research problem motivating this investigation is: How can an AI-assisted software system identify post-consumer municipal waste from an image and synthesize that identification into an immutable Digital Waste Passport containing material-specific circularity guidance and verified recycling facility recommendations?");

            AddHeading2("B. Technical Contributions");
            AddPara("To address this multi-faceted challenge, we present WasteWay, an end-to-end sustainable waste management platform developed as a fifth-semester mini-project at HKBK College of Engineering, Bengaluru. WasteWay makes five primary technical and methodological contributions:");
            AddBullet("1) Hybrid AI Classification Engine:", "Integrates multimodal vision analysis via Google Gemini 3.8 Flash with a zero-crash, 100-item offline taxonomy fallback to provide reliable material prediction without latency bottlenecks or cloud lock-in.");
            AddBullet("2) Digital Waste Passport (DWP):", "Adapts the industrial Digital Product Passport (DPP) paradigm to consumer municipal solid waste, structuring items with unique IDs, RIC codes, degradation timelines, embodied carbon estimates, and A–E recyclability grades.");
            AddBullet("3) Context-Aware Circularity Engine:", "Systematically operationalizes the Seven Rs (Refuse, Reduce, Reuse, Repurpose, Repair, Recycle, Recover) alongside specialized composting, donation, and safe disposal protocols.");
            AddBullet("4) Verified Recycler Directory:", "Matches identified material streams with authentic municipal DWCCs and certified scrap aggregators in Bengaluru via Haversine distance, strictly enforcing informational boundaries without physical logistics.");
            AddBullet("5) Segregated Civic Alert Workflow:", "Provides a secondary, dedicated module for photographic documentation and civic escalation of illegal dumping and public neglect to municipal authorities.");

            // ==================== SECTION II ====================
            AddHeading1("II. RELATED WORK");
            AddPara("Automated waste management and circular economy frameworks have witnessed significant academic inquiry across three primary thematic vectors: deep-learning-based visual classification, digital material information architectures, and community-driven environmental monitoring platforms.");
            
            AddHeading2("A. AI-Based Waste Image Classification");
            AddPara("Early computational approaches to solid waste identification relied on handcrafted visual features coupled with Support Vector Machines (SVMs) and Random Forests. The advent of Deep Convolutional Neural Networks (CNNs) revolutionized the domain. Malik et al. [6] conducted extensive benchmarks comparing ResNet50 and DenseNet121 on the standard TrashNet repository, achieving an 89.6% classification accuracy across six general waste classes. Li and Chen [7] integrated YOLOv5s and MobileNetV3 for real-time municipal solid waste detection in urban transfer stations, demonstrating high mean Average Precision (mAP) of 86.4% at an inference latency of 24 ms. Similarly, Mohamad Rastari et al. [8] developed a YOLOv8-based model achieving 87.2% precision on recyclable items. Other investigations by Mao et al. [10] utilized genetic algorithm optimizations to refine CNN hyper-parameters, reaching 94.6% accuracy on a restricted four-class dataset, while Nnamoko et al. [11] investigated VGG16 transfer learning on solid waste imagery.");
            
            AddPara("Feature fusion methodologies have further pushed empirical accuracy boundaries. Ahmad et al. [16] combined deep representations extracted from ResNet50 and DenseNet201, attaining 95.8% accuracy across the TrashNet and GINI datasets. Transfer learning paradigms applied to lightweight mobile architectures were examined by Yong et al. [19] using MobileNetV2 and Zhang et al. [18] utilizing fine-tuned CNN layers. However, a pervasive limitation across visual classification literature is that models operate in an isolated predictive vacuum: once an image is assigned a class label, no downstream decision-support mechanism is provided to guide physical processing.");

            AddHeading2("B. Digital Product Passports and Circularity");
            AddPara("The base paper for this study, formulated by Mateo-Casali et al. [1] at the 2025 IEEE ICE/ITMC Conference, establishes a comprehensive Reference Architecture for Digital Product Passports (DPPs) leveraging Artificial Intelligence within Industry 4.0 systems. Their architecture demonstrates how structured data models can track equipment lifecycles, maintenance intervals, and material circularity across manufacturing enterprises. Psarommatis and May [2] and Adisorn et al. [3] similarly emphasize that DPPs provide an indispensable data backbone for the circular economy by guaranteeing material transparency. Yu et al. [4] explored AI-driven environmental planning under the 4R framework (Reduce, Reuse, Recycle, Recover), while Kaiser et al. [5] systematically classified industrial reference architectures.");
            
            AddPara("Despite these advances, existing DPP implementations remain almost exclusively enterprise-focused, tracking complex machinery, batteries, and textiles across business-to-business (B2B) supply chains. Little research has examined adapting the digital passport concept to post-consumer municipal household waste, where consumer-facing simplicity and immediate disposal guidance are paramount.");

            // Insert Table I (Related Work Comparison)
            sel.ParagraphFormat.Alignment = 1;
            sel.ParagraphFormat.SpaceBefore = 5;
            sel.ParagraphFormat.SpaceAfter = 3;
            sel.Font.Size = 7.8f;
            sel.Font.Bold = 1;
            sel.TypeText("TABLE I. COMPARATIVE ANALYSIS OF RELATED WORK IN AI WASTE MANAGEMENT\n");
            
            dynamic t1Range = sel.Range;
            dynamic t1 = doc.Tables.Add(t1Range, 8, 7);
            t1.Borders.Enable = 1;
            t1.Range.Font.Name = "Times New Roman";
            t1.Range.Font.Size = 7.0f;
            
            string[,] t1Data = new string[,] {
                {"Ref.", "Author & Year", "Method", "Technique / Model", "Dataset", "Reported Metrics", "Key Limitation"},
                {"[6]", "Malik (2022)", "Supervised", "ResNet50 / DenseNet", "TrashNet (2.5k)", "Acc: 89.6%", "Degrades under dirty/wrinkled items"},
                {"[7]", "Li & Chen (2023)", "Supervised", "YOLOv5s / MobileNet", "Urban MSW (10.5k)", "mAP: 86.4%, 24ms", "High false-positives on occluded packs"},
                {"[8]", "Rastari (2023)", "Supervised", "YOLOv8n Detector", "Recycle-4k", "Prec: 87.2%, Rec: 84%", "Compute-heavy; lacks circular guidance"},
                {"[10]", "Mao et al. (2021)", "Supervised", "Genetic Optimized CNN", "Custom (4 classes)", "Acc: 94.6%", "Restricted to 4 rigid categories"},
                {"[11]", "Nnamoko (2022)", "Supervised", "Deep CNN / VGG16", "VN-Trash Dataset", "Acc: 91.2%", "Fails to distinguish soiled tissues"},
                {"[16]", "Ahmad (2020)", "Supervised", "ResNet+DenseNet Fusion", "TrashNet & GINI", "Acc: 95.8%", "Isolated classification; no facility routing"},
                {"[1]", "Mateo-Casali (25)", "Arch. Model", "Layered Industry 4.0 DPP", "Industrial Lifecycle", "Arch. Validated", "Heavy industrial B2B scope; no MSW"}
            };
            
            for (int r = 0; r < 8; r++) {
                for (int c = 0; c < 7; c++) {
                    dynamic cell = t1.Cell(r + 1, c + 1);
                    cell.Range.Text = t1Data[r, c];
                    if (r == 0) {
                        cell.Range.Font.Bold = 1;
                        cell.Shading.BackgroundPatternColor = 15132390; // #E8E8E8
                    }
                }
            }
            t1.Columns[1].Width = 22f;
            t1.Columns[2].Width = 46f;
            t1.Columns[3].Width = 36f;
            t1.Columns[4].Width = 56f;
            t1.Columns[5].Width = 42f;
            t1.Columns[6].Width = 44f;
            t1.Columns[7].Width = 60f;
            
            sel.SetRange(t1.Range.End + 1, t1.Range.End + 1);
            sel.ParagraphFormat.SpaceAfter = 4;
            
            AddHeading2("C. Inferences and Research Gap");
            AddPara("Four primary inferences emerge from the reviewed corpus: (1) Benchmark computer vision models exhibit severe accuracy degradation when exposed to food-soiled, crumpled, or multi-material household waste; (2) Classifying an object into a broad category does not resolve the user's practical uncertainty regarding preparation and disposal; (3) Digital Product Passports provide high traceability value but have never been tailored to consumer post-consumer waste items; and (4) Facility directories are frequently unverified, failing to inform users about strict material acceptance criteria. WasteWay directly bridges this research gap by creating an integrated, end-to-end framework uniting image capture, hybrid AI classification, Digital Waste Passport generation, 7-R circularity pathways, and verified localized recycler matching.");

            // ==================== SECTION III ====================
            AddHeading1("III. PROPOSED SYSTEM METHODOLOGY");
            AddPara("The WasteWay system methodology is designed around an end-to-end pipeline structured into six interconnected modules that preserve the approved project scope while enforcing strict architectural boundaries.");
            
            AddHeading2("A. Core Waste Identification Workflow");
            AddPara("The primary user workflow progresses through ten sequential operational phases: (1) The user initiates the capture interface via mobile camera or web file picker; (2) The client-side image processing service ingests raw bytes, strips EXIF privacy data, and compresses dimensions to a maximum of 1024x1024 pixels under 500 KB; (3) The hybrid AI dispatcher evaluates connectivity and passes the compressed payload to the live Gemini 3.8 Flash multimodal API or routes to the local offline taxonomy fallback; (4) The inference engine classifies the primary material, specific sub-type, and confidence score; (5) An immutable Digital Waste Passport (DWP) record is synthesized; (6) Physical material characteristics, recyclability grades (A–E), degradation times, and carbon metrics are presented; (7) Contextual 7-R circularity guidance is rendered; (8) Localized recycling centers accepting the exact material are matched via Haversine distance; (9) The user reviews handling instructions and selects an action; and (10) The DWP record is committed to local persistent storage.");

            AddHeading2("B. Digital Waste Passport (DWP) Architecture");
            AddPara("The Digital Waste Passport represents the core information artifact of WasteWay. Rather than functioning as a transient label, the DWP persists structured material provenance. Each generated passport contains: (1) A unique identification token (#DWP-2026-XXXX); (2) Recognized item name and material sub-type (e.g., PET Type 1, Metallized BOPP Film); (3) Percentage material composition breakdown; (4) Recyclability Grade from A (infinitely recyclable metals) to E (hazardous e-waste/batteries); (5) Environmental impact metrics, including estimated landfill degradation timeline and embodied carbon footprint (kg CO2e); and (6) Granular preparation protocols (e.g., rinse, flatten, separate caps).");

            AddHeading2("C. Circularity Guidance Engine (The Seven Rs)");
            AddPara("WasteWay operationalizes circular economy principles through a context-aware recommendation matrix structured around the Seven Rs: Refuse (avoiding single-use packaging), Reduce (minimizing consumption bulk), Reuse (domestic repurposing and upcycling), Repurpose (alternative functional utilities), Repair (fixability guides for appliances and textiles), Recycle (color-coded bin sorting and secondary re-granulation), and Recover (energy recovery and cement kiln co-processing for composite snack wrappers). In addition, specialized circular pathways are integrated: home and community composting for organic biomass, charitable donation (e.g., Goonj clothing drives) for wearable textiles, and manufacturer buyback drops for lithium cells and hazardous electronics.");

            AddHeading2("D. Localized Facility Recommendation System");
            AddPara("For recyclable streams, WasteWay connects users with verified recycling hubs. The engine maintains an audited directory of authentic facilities in the Greater Bengaluru metropolitan area. When a passport is active, the system filters facilities by material acceptance criteria, calculates geodesic distance using the Haversine formula based on reference user coordinates, and provides one-touch navigation via Google Maps and OpenStreetMap using url_launcher. Crucially, WasteWay acts purely as an informational and navigation bridge; it does NOT operate transport fleets, schedule door-to-door physical pickups, or handle financial transactions.");

            AddHeading2("E. Waste Management Education Hub");
            AddPara("To cultivate long-term behavioral change, WasteWay integrates an Educational Hub featuring Daily Eco-Insights, material degradation visualizers, and an interactive 5-question Segregation Quiz that provides immediate corrective explanations upon answer submission.");

            AddHeading2("F. Segregated Civic Alert Workflow");
            AddPara("A critical structural design decision is the strict architectural segregation of the Civic Alert module from domestic waste scanning. Accessed via a distinct route (/civic-reports), this secondary workflow allows citizens to report public space neglect, illegal garbage dumping, overflowing municipal bins, and waterway blockages. Users capture photographic evidence, input mandatory landmark descriptions, tag optional GPS coordinates, and assign severity ratings (Low to Emergency). A review-before-submit modal prevents accidental submissions, and an automated formal grievance summary directs citizens to official municipal authority portals (BBMP Sahaya / BSWML) without claiming direct unauthorized government database dispatch.");

            // ==================== SECTION IV ====================
            AddHeading1("IV. IMPLEMENTATION");
            AddPara("The implementation of WasteWay strictly mirrors the actual Flutter source code present in the project repository. The application is developed in Dart 3.x using the Flutter 3.x framework with Material 3 theming. Application state is coordinated via the provider package across dedicated change notifiers (ScannerProvider, PassportProvider, FacilityProvider, EducationProvider, CivicReportProvider). Deep linking and tab state persistence are managed through go_router utilizing StatefulShellRoute.indexedStack across four primary bottom-navigation tabs.");

            AddHeading2("A. Image Processing and AI Classification Pipeline");
            AddPara("The client-side image pipeline in image_processing_service.dart decodes captured image bytes using the image package, resizes high-resolution photographs to a maximum dimension of 1024x1024 pixels, compresses quality to 80% JPEG, and strips privacy-sensitive EXIF geolocation tags. This guarantees that transmission payloads remain strictly beneath 500 KB.");
            
            AddPara("Classification execution is governed by HybridAIClassificationService. When a valid Gemini API key is configured in private SharedPreferences, the system dispatches payloads to GeminiVisionService using Google's gemini-3.8-flash model. The service utilizes a rigorous system prompt demanding structured JSON conforming to materials science standards, Resin Identification Codes, recyclability grading, and non-waste rejection. When network connectivity fails or no API key is supplied, execution seamlessly switches to MockAIClassificationService backed by WasteTaxonomyRepository—a comprehensive knowledge base of 100 municipal waste items across 10 categories (Plastic, Paper, Glass, Metals, E-Waste, Batteries, Textiles, Organics, Hazardous Household, and Multi-Layer Composites). Explicit ambiguity resolution logic prevents common misclassifications, ensuring used paper tissues are never labeled as plastic bottles and snack wrappers are never misidentified as lithium batteries.");

            AddHeading2("B. Modular Firebase and Storage Layer");
            AddPara("WasteWay implements a dual-mode backend architecture encapsulated behind abstract interfaces (IAuthService, ICloudDatabaseService, ICloudStorageService). The cloud implementation interfaces directly with Cloud Firestore and Firebase Storage. To ensure flawless viva demonstration safety and complete privacy without active cloud billing, the system incorporates zero-crash mock fallback implementations (MockCloudDatabaseService, MockCloudStorageService) backed by on-device SharedPreferences. Passports, facility bookmarks, and civic reports persist reliably on-device across application restarts.");

            // Insert Table II (Component Implementation-Status Table)
            sel.ParagraphFormat.Alignment = 1;
            sel.ParagraphFormat.SpaceBefore = 5;
            sel.ParagraphFormat.SpaceAfter = 3;
            sel.Font.Size = 7.8f;
            sel.Font.Bold = 1;
            sel.TypeText("TABLE II. COMPONENT IMPLEMENTATION AND VERIFICATION STATUS\n");
            
            dynamic t2Range = sel.Range;
            dynamic t2 = doc.Tables.Add(t2Range, 11, 4);
            t2.Borders.Enable = 1;
            t2.Range.Font.Name = "Times New Roman";
            t2.Range.Font.Size = 7.0f;
            
            string[,] t2Data = new string[,] {
                {"Component", "Actual Implementation", "Status", "Source Evidence / Limitation"},
                {"Image Ingestion", "XFile byte decode, cross-platform", "Implemented & Verified", "image_picker, mobile & web tested"},
                {"Image Preprocessing", "1024px resize, 80% JPEG, <500KB", "Implemented & Verified", "image: ^4.3.0, unit test passed"},
                {"Live AI Classifier", "REST Gemini 3.8 Flash, JSON schema", "Implemented & Verified", "gemini_vision_service.dart"},
                {"Offline AI Fallback", "100-item taxonomy, rule disambiguation", "Implemented & Verified", "waste_taxonomy_repository.dart"},
                {"Digital Waste Passport", "DWP model, RIC, Grade A-E, Carbon", "Implemented & Verified", "waste_passport_model.dart, tests"},
                {"Circularity Engine", "7-Rs matrix, material-specific pathways", "Implemented & Verified", "circularity_screen.dart, verified"},
                {"Recycler Directory", "8 verified Bengaluru hubs, Haversine", "Implemented & Verified", "facility_provider.dart, maps launch"},
                {"Recycler Logistics", "Physical pickup, fleet dispatch", "Planned / Out of Scope", "Strictly informational & navigation"},
                {"Education Hub", "Daily tips, 5-question quiz, timelines", "Implemented & Verified", "education_provider.dart, verified"},
                {"Civic Alert Reporting", "Photo evidence, status tracking, review", "Implemented & Verified", "civic_reports_screen.dart, offline"}
            };
            
            for (int r = 0; r < 11; r++) {
                for (int c = 0; c < 4; c++) {
                    dynamic cell = t2.Cell(r + 1, c + 1);
                    cell.Range.Text = t2Data[r, c];
                    if (r == 0) {
                        cell.Range.Font.Bold = 1;
                        cell.Shading.BackgroundPatternColor = 15132390;
                    }
                }
            }
            t2.Columns[1].Width = 65f;
            t2.Columns[2].Width = 95f;
            t2.Columns[3].Width = 65f;
            t2.Columns[4].Width = 80f;
            
            sel.SetRange(t2.Range.End + 1, t2.Range.End + 1);
            sel.ParagraphFormat.SpaceAfter = 4;

            // ==================== SECTION V ====================
            AddHeading1("V. RESULTS AND DISCUSSION");
            AddPara("Evaluation of the WasteWay system was conducted across multiple empirical axes: static codebase analysis, automated test suite execution, cross-platform production compilation, and systematic classification benchmark evaluation.");

            AddHeading2("A. Test Suite and Compilation Evidence");
            AddPara("The project repository contains a rigorous automated testing framework encompassing unit tests, widget tests, and end-to-end integration flows. Full execution via 'flutter test' demonstrated that all 135 tests passed successfully (100% pass rate) with zero failures. Static code analysis executed through 'flutter analyze' concluded with zero errors, zero warnings, and zero linter infractions across the entire codebase.");
            
            AddPara("Production builds were verified across both target environments. The Android release APK (build/app/outputs/flutter-apk/app-release.apk, size: 56.9 MB / 59,687,082 bytes) was successfully compiled using Android NDK 28 (ndk/28.2.13676358) and CMake 3.22.1. The Web production deployment (build/web/) was compiled with CanvasKit rendering and PWA service worker caching, ensuring cross-platform responsiveness down to 320px viewport widths.");

            // Insert Screenshot Image
            if (File.Exists(imgPath)) {
                sel.ParagraphFormat.Alignment = 1; // Center
                sel.ParagraphFormat.SpaceBefore = 4;
                sel.ParagraphFormat.SpaceAfter = 2;
                dynamic shape = sel.InlineShapes.AddPicture(imgPath);
                shape.Width = 115f; // Scale to fit column
                shape.Height = imgHeight;
                sel.TypeText("\n");
                sel.Font.Size = 7.5f;
                sel.Font.Italic = 1;
                sel.Font.Bold = 0;
                sel.TypeText("Fig. 1. WasteWay application interface demonstrating the Digital Waste Passport and Circularity Guidance workflow on a mobile viewport.\n");
            }

            AddHeading2("B. Empirical Benchmark Evaluation");
            AddPara("To establish empirical classification performance without exaggerating real-world accuracy, an independent benchmark evaluation was conducted using waste_classification_benchmark_test.dart across 36 carefully curated test samples representing 10 solid waste categories and non-waste negative controls. As summarized in Table III, the model achieved an overall classification accuracy of 83.3% (30 correct out of 36), a macro precision of 90.9%, a macro recall of 81.8%, and a macro F1-score of 81.6%.");

            // Insert Table III (Benchmark Evaluation Metrics)
            sel.ParagraphFormat.Alignment = 1;
            sel.ParagraphFormat.SpaceBefore = 5;
            sel.ParagraphFormat.SpaceAfter = 3;
            sel.Font.Size = 7.8f;
            sel.Font.Bold = 1;
            sel.TypeText("TABLE III. EMPIRICAL BENCHMARK PERFORMANCE ACROSS WASTE CATEGORIES\n");
            
            dynamic t3Range = sel.Range;
            dynamic t3 = doc.Tables.Add(t3Range, 12, 5);
            t3.Borders.Enable = 1;
            t3.Range.Font.Name = "Times New Roman";
            t3.Range.Font.Size = 7.0f;
            
            string[,] t3Data = new string[,] {
                {"Material Category", "Samples", "Precision", "Recall", "F1-Score"},
                {"Paper & Cardboard", "6", "100.0%", "100.0%", "100.0%"},
                {"Textiles & Fabrics", "3", "100.0%", "100.0%", "100.0%"},
                {"Mixed Packaging Waste", "2", "100.0%", "100.0%", "100.0%"},
                {"Non-Waste Negatives", "4", "100.0%", "100.0%", "100.0%"},
                {"Multi-Layer Composites", "3", "75.0%", "100.0%", "85.7%"},
                {"Metals (Aluminium/Steel)", "3", "75.0%", "100.0%", "85.7%"},
                {"Biodegradable / Organic", "3", "100.0%", "66.7%", "80.0%"},
                {"Batteries (Li-Ion/Alkaline)", "3", "100.0%", "66.7%", "80.0%"},
                {"Glass Bottles & Jars", "3", "50.0%", "100.0%", "66.7%"},
                {"Plastic (Rigid PET/HDPE)", "3", "100.0%", "33.3%", "50.0%"},
                {"Electronic Waste (E-Waste)", "3", "100.0%", "33.3%", "50.0%"}
            };
            
            for (int r = 0; r < 12; r++) {
                for (int c = 0; c < 5; c++) {
                    dynamic cell = t3.Cell(r + 1, c + 1);
                    cell.Range.Text = t3Data[r, c];
                    if (r == 0) {
                        cell.Range.Font.Bold = 1;
                        cell.Shading.BackgroundPatternColor = 15132390;
                    }
                }
            }
            t3.Columns[1].Width = 105f;
            t3.Columns[2].Width = 35f;
            t3.Columns[3].Width = 55f;
            t3.Columns[4].Width = 55f;
            t3.Columns[5].Width = 55f;
            
            sel.SetRange(t3.Range.End + 1, t3.Range.End + 1);
            sel.ParagraphFormat.SpaceAfter = 4;

            AddHeading2("C. Error Analysis and Distractor Resilience");
            AddPara("A qualitative examination of the six misclassifications reveals important visual perception boundaries: (1) Translucent PET plastic beverage bottles were mistaken for Glass due to specular highlight reflections under direct illumination; (2) An opaque white HDPE milk jug was classified as Hazardous Household Waste due to visual shape confusion with industrial chemical containers; (3) A desiccated banana peel on a dark countertop was misclassified as Glass; (4) A metallic cylindrical 18650 lithium-ion cell was misclassified as Glass due to reflective casing glare; (5) A frayed white USB-C charging cable was identified as Metals due to exposed copper strands; and (6) A green printed circuit board (PCB) was classified as Multi-Layer Composite rather than E-Waste due to laminated epoxy resin layers. Importantly, the negative rejection control achieved 100% precision (4/4 non-waste samples rejected), and distractor resilience tests confirmed that tissues were never confused with bottles and snack wrappers were never misidentified as batteries.");

            AddHeading2("D. Recycling Facility Verification");
            AddPara("Auditing of the facility directory verified eight authentic recycling platforms in Bengaluru: Kabadify, KabadCart, Ecocrew, Bengaluru Solid Waste Management Limited (BSWML / BBMP), Saahas Zero Waste, ITC WOW, Hasiru Dala Innovations, and Goonj (textile donation). All entries maintain active HTTPS portals, validated accepted material lists, and explicit drop-off instructions.");

            // ==================== SECTION VI ====================
            AddHeading1("VI. LIMITATIONS");
            AddPara("A scientifically rigorous assessment requires identifying genuine operational and technical limitations:");
            AddBullet("1) Visual Ambiguity in Monocular RGB:", "RGB imagery cannot perform spectroscopic chemical identification. Distinguishing clear PET (#1) from clear PVC (#3) or LDPE (#4) packaging film from biodegradable PLA is unreliable without physical resin stamps or laboratory NIR spectroscopy.");
            AddBullet("2) Soiling and Deformation:", "Severe post-consumer deformation, crushing, mud accumulation, or grease staining degrades classification confidence, requiring reliance on user confirmation.");
            AddBullet("3) Local Infrastructure Disparity:", "While WasteWay recommends cement kiln coprocessing for multi-layer metallized chip pouches, such specialized processing channels are not uniformly available in all municipal wards.");
            AddBullet("4) Volatile Scrap Aggregator Economics:", "Commercial scrap buyback rates and operational hours fluctuate dynamically, requiring periodic directory validation.");
            AddBullet("5) Civic Alert Enforcement:", "The system provides structured documentation for citizen grievances but cannot compel municipal BBMP enforcement or guarantee timely physical clearance.");

            // ==================== SECTION VII ====================
            AddHeading1("VII. CONCLUSION AND FUTURE SCOPE");
            AddPara("WasteWay successfully demonstrates the feasibility of combining multimodal artificial intelligence with the Digital Product Passport paradigm to address post-consumer municipal solid waste challenges. Rather than treating visual classification as a terminal output, the system synthesizes identified items into structured Digital Waste Passports, delivers context-aware Seven-Rs circularity guidance, and connects citizens with verified recycling infrastructure in Bengaluru. The implementation preserves strict architectural boundaries between informational guidance and physical logistics, and separates civic neglect reporting into a dedicated workflow. Automated test verification (135 tests passed) and empirical benchmark evaluation (83.3% accuracy, 90.9% macro precision) confirm the functional robustness of the platform.");
            
            AddPara("Future research will focus on: (1) Quantizing lightweight edge neural networks (YOLOv8-nano / MobileNetV4) for on-device inference without cloud API dependencies; (2) Integrating automated barcode and optical QR scanning to extract verified manufacturer material bills; (3) Establishing authenticated API webhooks with municipal grievance portals (BBMP Sahaya) for automated civic ticket generation; and (4) Exploring community circularity gamification with municipal waste tax rebate incentives.");

            // ==================== REFERENCES ====================
            AddHeading1("REFERENCES");
            sel.ParagraphFormat.Alignment = 3; // Justify
            sel.ParagraphFormat.SpaceBefore = 0;
            sel.ParagraphFormat.SpaceAfter = 2.0f;
            sel.ParagraphFormat.LeftIndent = 11f;
            sel.ParagraphFormat.FirstLineIndent = -11f;
            sel.Font.Name = "Times New Roman";
            sel.Font.Size = refSize;
            sel.Font.Bold = 0;
            sel.Font.Italic = 0;

            string[] refs = new string[] {
                "[1] M. A. Mateo-Casali, L. Moya-Ruiz, A. Boza, and F. Fraile, \"Reference Architecture for Digital Product Passports: Leveraging AI in Industry 4.0 Systems,\" in Proc. 2025 IEEE Int. Conf. on Engineering, Technology and Innovation (ICE/ITMC), 2025, doi: 10.1109/ICE/ITMC65658.2025.11106524.",
                "[2] F. Psarommatis and G. May, \"Digital Product Passport: A Pathway to Circularity and Sustainability in Modern Manufacturing,\" Sustainability, vol. 16, no. 1, p. 396, 2024, doi: 10.3390/su16010396.",
                "[3] T. Adisorn, L. Tholen, and T. Götz, \"Towards a digital product passport fit for contributing to a circular economy,\" Energies, vol. 14, no. 8, p. 2289, 2021, doi: 10.3390/en14082289.",
                "[4] K. H. Yu, Y. Zhang, D. Li, C. E. Montenegro-Marin, and P. M. Kumar, \"Environmental planning based on reduce, reuse, recycle and recover using artificial intelligence,\" Environmental Impact Assessment Review, vol. 86, p. 106492, 2021, doi: 10.1016/j.eiar.2020.106492.",
                "[5] J. Kaiser, D. McFarlane, G. Hawkridge, P. André, and P. Leitão, \"A review of reference architectures for digital manufacturing: Classification, applicability and open issues,\" Computers in Industry, vol. 148, p. 103923, 2023, doi: 10.1016/j.compind.2023.103923.",
                "[6] M. Malik, S. Sharma, M. Uddin, C.-L. Chen, C.-M. Wu, P. Soni, and S. Chaudhary, \"Waste Classification for Sustainable Development Using Image Recognition with Deep Learning Neural Network Models,\" Sustainability, vol. 14, no. 12, p. 7222, 2022, doi: 10.3390/su14127222.",
                "[7] N. Li and Y. Chen, \"Municipal solid waste classification and real-time detection using deep learning methods,\" Urban Climate, vol. 49, p. 101462, 2023, doi: 10.1016/j.uclim.2023.101462.",
                "[8] M. A. Mohamad Rastari, R. Roslan, R. Hamzah, N. H. Ibrahim Teo, F. E. Shahbudin, and K. A. Fariza Abu Samah, \"Recycle Waste Detection and Classification Model Using YOLO-V8 for Real-time Waste Management,\" in Proc. IEEE Int. Conf. on Artificial Intelligence in Engineering and Technology (IICAIET), 2023, pp. 1–6.",
                "[9] A. Aishwarya, P. Wadhwa, O. Owais, and V. Vashisht, \"A Waste Management Technique to detect and separate Non-Biodegradable Waste using Machine Learning and YOLO algorithm,\" in Proc. 2021 11th Int. Conf. on Cloud Computing, Data Science & Engineering (Confluence), Noida, India, 2021, pp. 443–447, doi: 10.1109/Confluence51648.2021.9377163.",
                "[10] W.-L. Mao, W.-C. Chen, C.-T. Wang, and Y.-H. Lin, \"Recycling waste classification using optimized convolutional neural network,\" Resources, Conservation and Recycling, vol. 164, p. 105132, 2021, doi: 10.1016/j.resconrec.2020.105132.",
                "[11] N. Nnamoko, J. Barrowclough, and J. Procter, \"Solid Waste Image Classification Using Deep Convolutional Neural Network,\" Infrastructures, vol. 7, no. 4, p. 47, 2022, doi: 10.3390/infrastructures7040047.",
                "[12] S. Kunwar, \"Managing Household Waste Through Transfer Learning,\" arXiv preprint arXiv:2402.09437, 2024, doi: 10.48550/arXiv.2402.09437.",
                "[13] C. Wang, J. Qin, C. Qu, X. Ran, C. Liu, and B. Chen, \"A smart municipal waste management system based on deep-learning and Internet of Things,\" Waste Management, vol. 135, pp. 20–29, 2021, doi: 10.1016/j.wasman.2021.08.028.",
                "[14] M. W. Rahman, R. Islam, A. Hasan, N. I. Bithi, M. M. Hasan, and M. M. Rahman, \"Intelligent waste management system using deep learning with IoT,\" Journal of King Saud University - Computer and Information Sciences, vol. 34, no. 5, pp. 2072–2087, 2022, doi: 10.1016/j.jksuci.2020.08.016.",
                "[15] F. A. Azis, H. Suhaimi, and E. Abas, \"Waste Classification using Convolutional Neural Network,\" in Proc. 2020 2nd Int. Conf. on Information Technology and Computer Communications (ITCC '20), New York, NY, USA, 2020, pp. 9–13, doi: 10.1145/3417473.3417474.",
                "[16] K. Ahmad, K. Khan, and A. Al-Fuqaha, \"Intelligent Fusion of Deep Features for Improved Waste Classification,\" IEEE Access, vol. 8, pp. 96495–96504, 2020, doi: 10.1109/ACCESS.2020.2995681.",
                "[17] X. Bian, Y. Chen, S. Wang, F. Cheng, and H. Cao, \"Medical Waste Classification System Based on OpenCV and SSD-MobileNet for 5G,\" in Proc. 2021 IEEE Wireless Communications and Networking Conference Workshops (WCNCW), Nanjing, China, 2021, pp. 1–6, doi: 10.1109/WCNCW49093.2021.9420036.",
                "[18] Q. Zhang, Q. Yang, X. Zhang, Q. Bao, J. Su, and X. Liu, \"Waste image classification based on transfer learning and convolutional neural network,\" Waste Management, vol. 135, pp. 150–157, 2021, doi: 10.1016/j.wasman.2021.08.038.",
                "[19] L. Yong, L. Ma, D. Sun, and L. Du, \"Application of MobileNetV2 to waste classification,\" PLoS ONE, vol. 18, no. 3, p. e0282336, 2023, doi: 10.1371/journal.pone.0282336.",
                "[20] Y. Chen, J. Sun, and S. Bi, \"Multi-objective solid waste classification and identification model based on transfer learning method,\" Journal of Material Cycles and Waste Management, vol. 23, no. 6, pp. 2179–2191, 2021, doi: 10.1007/s10163-021-01283-8."
            };

            foreach (var r in refs) {
                sel.TypeText(r + "\n");
            }

            // Save docx
            doc.SaveAs2(docxPath);
            
            // Check page count
            int pageCount = doc.ComputeStatistics(2); // wdStatisticPages
            
            // Export PDF
            doc.ExportAsFixedFormat(pdfPath, 17); // wdFormatPDF = 17
            
            doc.Close(false);
            return pageCount;
        } finally {
            word.Quit();
        }
    }
}
'@

Add-Type -TypeDefinition $code -Language CSharp -ReferencedAssemblies "Microsoft.CSharp"

$docx = "C:\Users\chand\OneDrive\Documents\waste way\WasteWay_IEEE_Research_Paper_Final.docx"
$pdf = "C:\Users\chand\OneDrive\Documents\waste way\WasteWay_IEEE_Research_Paper_Final.pdf"
$img = "C:\Users\chand\OneDrive\Documents\waste way\app_screenshot_evidence.png"

# Test parameter sweep to find EXACT 6 PAGES
$configs = @(
    @{ body = [float]9.5; para = [float]2.5; top = [float]45.0; bot = [float]45.0; imgH = [float]240.0; refS = [float]7.2 },
    @{ body = [float]9.4; para = [float]2.2; top = [float]44.0; bot = [float]44.0; imgH = [float]230.0; refS = [float]7.0 },
    @{ body = [float]9.6; para = [float]2.8; top = [float]46.0; bot = [float]46.0; imgH = [float]250.0; refS = [float]7.2 },
    @{ body = [float]9.3; para = [float]2.0; top = [float]42.0; bot = [float]42.0; imgH = [float]220.0; refS = [float]6.8 }
)

function Get-PdfPageCount($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    $regex = [regex]'/Type\s*/Page[^s]'
    $matches = $regex.Matches($text)
    return $matches.Count
}

foreach ($c in $configs) {
    Write-Output "Testing config: body=$($c.body), para=$($c.para), top=$($c.top), imgH=$($c.imgH)..."
    $pages = [PaperGenerator]::GeneratePaper($docx, $pdf, $img, $c.body, $c.para, $c.top, $c.bot, $c.imgH, $c.refS)
    $pdfPages = Get-PdfPageCount $pdf
    Write-Output "Result: Word Pages = $pages | PDF Pages = $pdfPages"
    if ($pages -eq 6 -and $pdfPages -eq 6) {
        Write-Output ">>> PERFECT MATCH: EXACTLY 6 PAGES ACHIEVED! <<<"
        break
    }
}

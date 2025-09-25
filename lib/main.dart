import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ARAnimatedView(),
    );
  }
}

class ARAnimatedView extends StatefulWidget {
  const ARAnimatedView({super.key});

  @override
  State<ARAnimatedView> createState() => _ARAnimatedViewState();
}

class _ARAnimatedViewState extends State<ARAnimatedView> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  // Model lokal
  final String animatedModel = "assets/maskot.glb";

  ARNode? placedObject;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    // Set callback tap pada plane
    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    print("AR View created successfully. NodeType available: gltfLocal");
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (placedObject != null) return;

    try {
      final hitTestResult = hitTestResults.first;
      print("Tap detected on plane at: ${hitTestResult.worldTransform}");

      final newNode = ARNode(
        type: NodeType.localGLTF2, //
        uri: animatedModel,
        scale: vm.Vector3(0.5, 0.5, 0.5),
        position: vm.Vector3(0.0, 0.0, 0.0),
        rotation: vm.Vector4(0.0, 0.0, 0.0, 1.0), // quaternion (default identity)
        name: "animated_character",
      );
      
      final didAddNode = await this.arObjectManager!.addNode(newNode);
      if (didAddNode == true) {  // Null safety untuk bool?
        placedObject = newNode;
        print("Objek ditempatkan pada plane. Animasi otomatis jika model support.");
        if (mounted) setState(() {});
      } else {
        print("Gagal add node (returned false or null).");
      }
    } catch (e) {
      print("Error on tap: $e");
    }
  }

  Future<void> removeObject() async {
    if (placedObject != null) {
      await this.arObjectManager!.removeNode(placedObject!);
      placedObject = null;
      if (mounted) setState(() {});
      print("Objek dihapus.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("njajal AR"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: removeObject,
            tooltip: "Hapus Objek",
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,  // Signature sekarang match ARViewCreatedCallback
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          if (placedObject == null)
            const Center(
              child: Card(
                color: Colors.white70,
                margin: EdgeInsets.all(20),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Pindai permukaan datar lalu ketuk untuk menempatkan karakter beranimasi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
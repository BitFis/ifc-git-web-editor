import { AmbientLight, AxesHelper, DirectionalLight, GridHelper, PerspectiveCamera, Scene, WebGLRenderer } from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { IFCLoader } from "web-ifc-three/IFCLoader";
import * as THREE from 'three';

import "./styles.css";

//Creates the Three.js scene
const scene = new Scene();

// Sets up the IFC loading
const ifcLoader = new IFCLoader();

const inputX = document.getElementById("x-pos");
const inputY = document.getElementById("y-pos");
const inputZ = document.getElementById("z-pos");

function setInput(vector) {
  inputX.value = vector.x;
  inputY.value = vector.y;
  inputZ.value = vector.z;
}

function centerObject(ifcModel) {
  let geometry = ifcModel.geometry;
  let middle = new THREE.Vector3();
  geometry.computeBoundingBox();
  geometry.boundingBox.getCenter(middle)
  let pos = ifcModel.localToWorld(middle);

  ifcModel.translateX(-pos.x);
  ifcModel.translateY(-pos.y);
  ifcModel.translateZ(-pos.z);
}

function loadIFC(ifcURL) {
  console.log(`load ifc loader ... ${ifcURL}`);
  ifcLoader.load(ifcURL, (ifcModel) => {
    // move ifc model to center
    centerObject(ifcModel);
    return scene.add(ifcModel);
  });
}

// loader for file
const input = document.getElementById("file-input");
input.addEventListener(
  "change",
  (changed) => {
    const file = changed.target.files[0];
    window.file = file;
    loadIFC(URL.createObjectURL(file));
  },
  false
);

// mediaSource.sour
//
loadIFC("s/examples/modell_mvp_v01.ifc");


//Object to store the size of the viewport
const size = {
  width: window.innerWidth,
  height: window.innerHeight,
};

//Creates the camera (point of view of the user)
const aspect = size.width / size.height;
const camera = new PerspectiveCamera(75, aspect);
camera.position.z = 15;
camera.position.y = 13;
camera.position.x = 8;

//Creates the lights of the scene
const lightColor = 0xffffff;

const ambientLight = new AmbientLight(lightColor, 0.5);
scene.add(ambientLight);

const directionalLight = new DirectionalLight(lightColor, 1);
directionalLight.position.set(0, 10, 0);
directionalLight.target.position.set(-5, 0, 0);
scene.add(directionalLight);
scene.add(directionalLight.target);

//Sets up the renderer, fetching the canvas of the HTML
const threeCanvas = document.getElementById("three-canvas");
const renderer = new WebGLRenderer({
  canvas: threeCanvas,
  alpha: true,
});

renderer.setSize(size.width, size.height);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

//Creates grids and axes in the scene
const grid = new GridHelper(50, 30);
scene.add(grid);

const axes = new AxesHelper();
axes.material.depthTest = false;
axes.renderOrder = 1;
scene.add(axes);

//Creates the orbit controls (to navigate the scene)
const controls = new OrbitControls(camera, threeCanvas);
controls.enableDamping = true;
controls.target.set(-2, 0, 0);

//Animation loop
const animate = () => {
  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
};

animate();

//Adjust the viewport to the size of the browser
window.addEventListener("resize", () => {
  size.width = window.innerWidth;
  size.height = window.innerHeight;
  camera.aspect = size.width / size.height;
  camera.updateProjectionMatrix();
  renderer.setSize(size.width, size.height);
});

console.log(`${new Date()}`);

import cv2
import numpy as np
import mediapipe as mp
import matplotlib.pyplot as plt
import tensorflow as tf
from tensorflow import keras

# Mencegah error visual dari linter Pylance di VS Code
load_model = keras.models.load_model
preprocess_input = keras.applications.efficientnet.preprocess_input

# =========================================================
# LOAD MODEL
# =========================================================

face_model = load_model(
    "C:/Users/Adji/Documents/Kuliah/Skripsi/Dataset/pretrained_model/mobilefacenet_best.keras"
)

hair_model = load_model(
    "C:/Users/Adji/Documents/Kuliah/Skripsi/Dataset/pretrained_model/efficientnet_best.keras"
)

hair_type_model = load_model(
    "C:/Users/Adji/Documents/Kuliah/Skripsi/Dataset/pretrained_model/efficientnet_type_best.keras"
)

# =========================================================
# LABEL CLASS (Disamakan dengan output alphabet saat training)
# =========================================================

# face_classes = ['Heart', 'Oval', 'Round', 'Square']
face_classes = ['Oval', 'Round', 'Square']
hair_classes = ['medium', 'thick', 'thin']  # 3 Kelas sesuai training Anda
hair_type_classes = ['Straight', 'Wavy', 'curly']  # 3 kelas tipe rambut

# =========================================================
# RECOMMENDATION ENGINE
# =========================================================

recommendations = {
    ('Oval', 'thick', 'Straight'): ['pompadour', 'quiff', 'slick_back'],
    ('Oval', 'thick', 'Wavy'):    ['textured_crop', 'comb_over', 'quiff'],
    ('Oval', 'thick', 'curly'):   ['curly_top', 'undercut', 'faux_hawk'],
    ('Oval', 'medium', 'Straight'): ['side_part', 'french_crop', 'pompadour'],
    ('Oval', 'medium', 'Wavy'):    ['side_part', 'textured_crop', 'quiff'],
    ('Oval', 'medium', 'curly'):   ['curly_top', 'textured_crop', 'undercut'],
    ('Oval', 'thin', 'Straight'):  ['side_part', 'french_crop', 'textured_crop'],
    ('Oval', 'thin', 'Wavy'):      ['comb_over', 'textured_crop', 'side_part'],
    ('Oval', 'thin', 'curly'):     ['curly_top', 'textured_crop', 'undercut'],

    ('Round', 'thick', 'Straight'): ['undercut', 'faux_hawk', 'buzz_cut'],
    ('Round', 'thick', 'Wavy'):    ['faux_hawk', 'quiff', 'textured_crop'],
    ('Round', 'thick', 'curly'):   ['curly_top', 'undercut', 'faux_hawk'],
    ('Round', 'medium', 'Straight'): ['quiff', 'slick_back', 'undercut'],
    ('Round', 'medium', 'Wavy'):    ['side_part', 'textured_crop', 'quiff'],
    ('Round', 'medium', 'curly'):   ['curly_top', 'undercut', 'textured_crop'],
    ('Round', 'thin', 'Straight'):  ['side_part', 'comb_over', 'buzz_cut'],
    ('Round', 'thin', 'Wavy'):      ['comb_over', 'side_part', 'textured_crop'],
    ('Round', 'thin', 'curly'):     ['curly_top', 'undercut', 'textured_crop'],

    ('Square', 'thick', 'Straight'): ['buzz_cut', 'crew_cut', 'undercut'],
    ('Square', 'thick', 'Wavy'):    ['textured_crop', 'faux_hawk', 'quiff'],
    ('Square', 'thick', 'curly'):   ['curly_top', 'undercut', 'textured_crop'],
    ('Square', 'medium', 'Straight'): ['side_part', 'french_crop', 'slick_back'],
    ('Square', 'medium', 'Wavy'):    ['textured_crop', 'side_part', 'quiff'],
    ('Square', 'medium', 'curly'):   ['curly_top', 'textured_crop', 'undercut'],
    ('Square', 'thin', 'Straight'):  ['textured_crop', 'french_crop', 'side_part'],
    ('Square', 'thin', 'Wavy'):      ['textured_crop', 'comb_over', 'side_part'],
    ('Square', 'thin', 'curly'):     ['curly_top', 'undercut', 'textured_crop']
}

# =========================================================
# MEDIAPIPE TASK API
# =========================================================

BaseOptions = mp.tasks.BaseOptions
FaceDetector = mp.tasks.vision.FaceDetector
FaceDetectorOptions = mp.tasks.vision.FaceDetectorOptions
VisionRunningMode = mp.tasks.vision.RunningMode

options = FaceDetectorOptions(
    base_options=BaseOptions(
        model_asset_path="C:/Users/Adji/Documents/Kuliah/Skripsi/Dataset/pretrained_model/blaze_face_short_range.tflite"
    ),
    running_mode=VisionRunningMode.IMAGE,
    min_detection_confidence=0.5
)

detector = FaceDetector.create_from_options(options)

# =========================================================
# PREPROCESSING FUNCTIONS
# =========================================================

def preprocess_mobilefacenet(face_crop):
    img = cv2.resize(face_crop, (112, 112))
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = img.astype("float32") / 255.0
    img = np.expand_dims(img, axis=0)
    return img


def preprocess_efficientnet(face_crop):
    # FIXED: Menggunakan standar preprocessing EfficientNet bawaan tanpa pembagian manual
    img = cv2.resize(face_crop, (224, 224))
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = img.astype("float32")
    img = np.expand_dims(img, axis=0)
    img = preprocess_input(img)
    return img

# =========================================================
# LOAD IMAGE
# =========================================================

image_path = "C:/Users/Adji/Documents/Kuliah/Skripsi/Dataset/pretrained_model/foto/test_depan.jpeg"

image = cv2.imread(image_path)

if image is None:
    raise ValueError("Gambar tidak ditemukan!")

original = image.copy()

# =========================================================
# FACE DETECTION (Bagian MediaPipe)
# =========================================================

rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

mp_image = mp.Image(
    image_format=mp.ImageFormat.SRGB,
    data=rgb
)

detection_result = detector.detect(mp_image)

# =========================================================
# SAVING RESULT LOG
# =========================================================

def save_log(face_shape, face_conf, hair_density, hair_type, hair_density_conf, hair_type_conf, filename="temp_confidence.txt"):
    with open(filename, "a") as f:
        f.write("==============================\n")
        f.write(f"FACE SHAPE      : {face_shape}\n")
        f.write(f"FACE CONFIDENCE : {face_conf:.2f}%\n")
        f.write(f"HAIR DENSITY    : {hair_density}\n")
        f.write(f"DENSITY CONF    : {hair_density_conf:.2f}%\n")
        f.write(f"HAIR TYPE       : {hair_type}\n")
        f.write(f"TYPE CONF       : {hair_type_conf:.2f}%\n")
        f.write("==============================\n\n")

# =========================================================
# CHECK DETECTION & PROCESSING
# =========================================================

if len(detection_result.detections) == 0:
    print("Wajah tidak terdeteksi!")
else:
    for detection in detection_result.detections:
        bbox = detection.bounding_box

        x = bbox.origin_x
        y = bbox.origin_y
        width = bbox.width
        height = bbox.height

        # --------------------------
        # FACE CROP
        # --------------------------
        face_crop = image[y:y+height, x:x+width]

        # --------------------------
        # HAIR CROP
        # --------------------------
        expand_top = int(height * 0.6)
        expand_side = int(width * 0.25)

        x_hair = max(0, x - expand_side)
        y_hair = max(0, y - expand_top)

        w_hair = min(image.shape[1] - x_hair, width + 2 * expand_side)
        h_hair = min(image.shape[0] - y_hair, height + expand_top)

        hair_crop = image[y_hair:y_hair+h_hair, x_hair:x_hair+w_hair]

        # --------------------------
        # MODEL INPUT PREPARATION
        # --------------------------
        face_input = preprocess_mobilefacenet(face_crop)
        hair_input = preprocess_efficientnet(hair_crop)

        # -------------------------------------------------
        # FIXED: FILTER ORANG BOTAK (ANALISIS HOMOGENITAS WARNA KULIT)
        # -------------------------------------------------
        gray_hair = cv2.cvtColor(hair_crop, cv2.COLOR_BGR2GRAY)
        _, std_dev = cv2.meanStdDev(gray_hair)
        std_dev_value = std_dev[0][0]
        
        print(f"\n[DEBUG] Standar Deviasi Piksel Rambut: {std_dev_value:.2f}")

        # Jika variasi piksel di bawah threshold, kepala dianggap botak licin (homogen)
        # Nilai 28.0 sangat ideal untuk membedakan kulit kepala mulus vs tekstur rambut tipis
        IS_BALD = std_dev_value < 50.0 

        # --------------------------
        # FACE SHAPE PREDICTION
        # --------------------------
        face_pred = face_model.predict(face_input)
        face_idx = np.argmax(face_pred)
        face_shape = face_classes[face_idx]
        face_conf = np.max(face_pred) * 100

        # -------------------------------------------------
        # HAIR DENSITY & HAIR TYPE PREDICTION
        # -------------------------------------------------
        if IS_BALD:
            hair_density = "Bald / No Hair"
            hair_conf = 100.0  # Kepastian penuh dari filter OpenCV
            hair_type = "None"
            hair_type_conf = 100.0
            result = ["Tidak ada rekomendasi gaya rambut untuk kepala botak."]
        else:
            hair_pred = hair_model.predict(hair_input)
            hair_idx = np.argmax(hair_pred)
            hair_density = hair_classes[hair_idx]
            hair_conf = np.max(hair_pred) * 100

            type_pred = hair_type_model.predict(hair_input)
            type_idx = np.argmax(type_pred)
            hair_type = hair_type_classes[type_idx]
            hair_type_conf = np.max(type_pred) * 100

            # Ambil rekomendasi gaya rambut dari dictionary dengan kombinasi face shape, density, dan type
            result = recommendations.get((face_shape, hair_density, hair_type))
            if result is None:
                result = recommendations.get((face_shape, hair_density), ["No Recommendation"])

        # --------------------------
        # PRINT & LOG RESULTS
        # --------------------------
        save_log(face_shape, face_conf, hair_density, hair_type, hair_conf, hair_type_conf)
        
        print("\n==============================")
        print("FACE SHAPE :", face_shape)
        print(f"CONFIDENCE : {face_conf:.2f}%")

        print("\nHAIR DENSITY :", hair_density)
        print(f"DENSITY CONFIDENCE : {hair_conf:.2f}%")
        print("HAIR TYPE :", hair_type)
        print(f"TYPE CONFIDENCE : {hair_type_conf:.2f}%")

        print("\nRECOMMENDED HAIRSTYLES:")
        for hairstyle in result:
            print("-", hairstyle)
        print("==============================")

        # --------------------------
        # VISUALIZATION
        # --------------------------
        cv2.rectangle(original, (x, y), (x + width, y + height), (0, 255, 0), 2)
        cv2.rectangle(original, (x_hair, y_hair), (x_hair + w_hair, y_hair + h_hair), (255, 0, 0), 2)

        label_text = f"{hair_density}, {hair_type}"
        cv2.putText(original, face_shape, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        cv2.putText(original, label_text, (x_hair, y_hair - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)

# =========================================================
# SHOW & SAVE VISUAL RESULT
# =========================================================

plt.figure(figsize=(10, 10))
plt.imshow(cv2.cvtColor(original, cv2.COLOR_BGR2RGB))
plt.axis("off")
plt.title("Face Shape & Hair Density Prediction")

temp_path = "temp_result.jpg"
cv2.imwrite(temp_path, original)
print(f"Hasil visualisasi baru disimpan ke: {temp_path}")
plt.show()
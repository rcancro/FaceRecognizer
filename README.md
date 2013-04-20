# iOS Face Detection & Recognition #
This is an example iPhone app that runs face detection and recognition on a given set of images.  Detection uses both the built in face detection is iOS 6 or (if you change the ifdef) face detection from [OpenCV](http://www.opencv.org).  This project is using the Eigenfaces algorithm to recognize faces, though this is easily changed to Fisherfaces or Local Binary Patterns Histogram using OpenCV. 

# Usage #
In order to use the app you'll need to add some pictures to the folder FaceRecognition/Faces.  I used [bulkr](http://clipyourphotos.com/bulkr) to download most of my photos from flickr and stuck them in the project.  

Once you open the app it will look for faces in all the images in the Faces directory.  The first tab, "Known Faces" will be blank when you start.  Tap on the "Unknown Faces" tab and start putting names to faces.  Tap on a photo of someone and provide a name.  Once you start doing this the photos of the known people will show under the "Known Faces" tab.

Once you have tagged enough people, tap on "Guesses".  The app will automatically use the images you have tagged to try to recognize faces from the images you have not tagged.  From this screen you can easily verify that a guess is correct or scold the recognizer and tell it the real person.  The more faces you tag, the better the recognition appears to get (I have been pretty unimpressed with it in the early stages).  Each face benefits from having 10+ (probably closer to 20-30) tags photos.  

When OpenCV tries to recognize a face a "confidence" is returned.  I set a default threshold, but you can change it from the "Threshold" button the "Guesses" tab.  Usually around 50-60 works well.  Anything much higher and not much comes back.

# Notes #
This was a proof of concept exercise for me.  Hopefully the source code is useful for you.  I saved all my photo info in Core Data and the time consuming operations (face detection and recognition) were done using NSOperations.  You should be able to use the files FaceRecognizer.h/.mm and FaceDetector.h/.mm regardless of what model you choose.  These classes basically act as wrappers around the OpenCV C++ objects.



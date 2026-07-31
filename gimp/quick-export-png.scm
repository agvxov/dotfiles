(define (script-fu-quick-export-png image drawable)
  (let* ((export-dir (string-append (getenv "HOME") "/Documents/"))
         (rand-name (number->string (random 1000000000)))
         (filename (string-append "gimp-quick-exports-" rand-name ".png"))
         (filepath (string-append export-dir filename))
         (flat-image (car (gimp-image-duplicate image))))
    (gimp-image-merge-visible-layers flat-image CLIP-TO-IMAGE)
    (file-png-export RUN-NONINTERACTIVE
                      flat-image
                      filepath
                      0)
    (gimp-image-delete flat-image)
    (gimp-displays-flush)))

(script-fu-register
 "script-fu-quick-export-png"
 "Quick Export PNG"
 "Export flattened image to PNG with an auto-generated unique filename"
 "you"
 "you"
 "2026"
 "*"
 SF-IMAGE "Image" 0
 SF-DRAWABLE "Drawable" 0)

(script-fu-menu-register "script-fu-quick-export-png" "<Image>/File/Export")

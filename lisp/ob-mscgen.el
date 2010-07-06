;;; ob-msc.el --- org-babel functions for mscgen evaluation

;; Copyright (C) 2010  Free Software Foundation, Inc.

;; Author: Juan Pechiar
;; Keywords: literate programming, reproducible research
;; Homepage: http://orgmode.org
;; Version: 0.01

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This software provides EMACS org-babel export support for message
;; sequence charts. The mscgen utility is used for processing the
;; sequence definition, and must therefore be installed in the system.
;;
;; Mscgen is available and documented at http://www.mcternan.me.uk/mscgen/index.html
;;
;; This code is directly inspired by Eric Schulte's ob-dot.el
;;
;; Example:
;;
;; #+begin_src mscgen :file example.png
;; msc {
;;  A,B;
;;  A -> B [ label = "send message" ];
;;  A <- B [ label = "get answer" ];
;; }
;; #+end_src
;;
;; Header for alternative file type:
;;
;; #+begin_src mscgen :file ex2.svg :filetype svg

;; This differs from most standard languages in that
;;
;; 1) there is no such thing as a "session" in mscgen
;; 2) we are generally only going to return results of type "file"
;; 3) we are adding the "file" and "filetype" header arguments
;; 4) there are no variables

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:mscgen
  '((:results . "file") (:exports . "results"))
  "Default arguments to use when evaluating a mscgen source block.")

(defun org-babel-expand-body:mscgen (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body." body)

(defun org-babel-execute:mscgen (body params)
  "Execute a block of Mscgen code with org-babel.  This function is
called by `org-babel-execute-src-block'.
Default filetype is png. Modify by setting :filetype parameter to mscgen supported formats."
  (message "executing Mscgen source code block")
  (let* ((out-file (or (cdr (assoc :file params)) "output.png" ))
         exit-code
         (filetype (or (cdr (assoc :filetype params)) "png" ))
         (stderr
          (with-temp-buffer
            (insert body)
            (setq exit-code (org-babel-shell-command-on-region
                             (point-min) (point-max) (concat "mscgen -T " filetype " -o " out-file)
                             nil 'replace (current-buffer)))
            (buffer-string))))
    (unless (cdr (assoc :file params)) (setq stderr (concat stderr "\nERROR: no output file specified. Add \":file some_name.png\" to the src header" )) (error stderr))
    (if (> exit-code 0) (org-babel-error-notify exit-code stderr))
    out-file))

(defun org-babel-prep-session:mscgen (session params)
  "Prepare SESSION according to PARAMS."
  (error "Mscgen does not support sessions"))

(provide 'ob-mscgen)

;; arch-tag: 74695b1e-715f-4b5a-a3a9-d78ee39ba5c8

;;; ob-msc.el ends here

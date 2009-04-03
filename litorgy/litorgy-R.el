;;; litorgy-R.el --- litorgy functions for R code evaluation

;; Copyright (C) 2009 Eric Schulte

;; Author: Eric Schulte
;; Keywords: literate programming, reproducible research, R, statistics
;; Homepage: http://orgmode.org
;; Version: 0.01

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Litorgy support for evaluating R code

;;; Code:
(require 'litorgy)

(litorgy-add-interpreter "R")

(defun litorgy-execute:R (body params)
  "Execute a block of R code with litorgy.  This function is
called by `litorgy-execute-src-block'."
  (message "executing R source code block...")
  (save-window-excursion
    (let ((vars (litorgy-ref-variables params))
          results)
      (message (format "--%S--" vars))
      (mapc (lambda (pair)
              (litorgy-R-input-command
               (format "%s <- %s" (car pair) (cdr pair))))
            vars)
      (litorgy-R-initiate-R-buffer)
      (litorgy-R-command-to-string body))))

;; functions for evaluation of R code
(defvar litorgy-R-buffer nil
  "Holds the buffer for the current R process")

(defun litorgy-R-initiate-R-buffer ()
  "If there is not a current R process then create one."
  (unless (and (buffer-live-p litorgy-R-buffer) (get-buffer litorgy-R-buffer))
    (save-excursion
      (R)
      (setf litorgy-R-buffer (current-buffer))
      (litorgy-R-wait-for-output)
      (litorgy-R-input-command ""))))

(defun litorgy-R-command-to-string (command)
  "Send a command to R, and return the results as a string."
  (litorgy-R-input-command command)
  (litorgy-R-last-output))

(defun litorgy-R-input-command (command)
  "Pass COMMAND to the R process running in `litorgy-R-buffer'."
  (save-excursion
    (save-match-data
      (set-buffer litorgy-R-buffer)
      (goto-char (process-mark (get-buffer-process (current-buffer))))
      (insert command)
      (comint-send-input)
      (litorgy-R-wait-for-output))))

(defun litorgy-R-wait-for-output ()
  "Wait until output arrives"
  (save-excursion
    (save-match-data
      (set-buffer litorgy-R-buffer)
      (while (progn
	       (goto-char comint-last-input-end)
	       (not (re-search-forward comint-prompt-regexp nil t)))
	(accept-process-output (get-buffer-process (current-buffer)))))))

(defun litorgy-R-last-output ()
  "Return the last R output as a string"
  (save-excursion
    (save-match-data
      (set-buffer litorgy-R-buffer)
      (goto-char (process-mark (get-buffer-process (current-buffer))))
      (forward-line 0)
      (let ((raw (buffer-substring comint-last-input-end (- (point) 1)))
            output output-flag)
        (mapconcat
         (lambda (el)
           (if (stringp el)
               (format "%s" el)
             (format "%S" el)))
         (delq nil
               (mapcar
                (lambda (line)
                  (unless (string-match "^>" line)
                    (and (string-match "\\[[[:digit:]]+\\] *\\(.*\\)$" line)
                         (match-string 1 line))))
                ;; drop first, because it's the last line of input
                (cdr (split-string raw "[\n\r]")))) "\n")))))

(defun litorgy-R-table-or-results (results)
  "If the results look like a matrix, then convert them into an
Emacs-lisp table otherwise return the results as a string."
  ;; TODO: these simple assumptions will probably need some tweaking
  (when (string-match "[ \f\t\n\r\v]+" results)
    (concat "(" (mapconcat #'litorgy-R-tale-or-results
                           (split-string results) " ") ")"))
  results)

(provide 'litorgy-R)
;;; litorgy-R.el ends here

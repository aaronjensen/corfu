;;; corfu-quick.el --- Quick keys for Corfu -*- lexical-binding: t -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; Author: Luis Henriquez-Perez <luis@luishp.xyz>, Daniel Mendler <mail@daniel-mendler.de>
;; Maintainer: Daniel Mendler <mail@daniel-mendler.de>
;; Created: 2022
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (corfu "0.21"))
;; Homepage: https://github.com/minad/corfu

;; This file is part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is a Corfu extension, which prefixes candidates with
;; quick keys. Typing these quick keys allows you to select the
;; candidate in front of them. This is designed to be a faster
;; alternative to selecting a candidate with `corfu-next' and
;; `corfu-previous'.
;; (define-key corfu-map "\M-q" #'corfu-quick-complete)
;; (define-key corfu-map "\C-q" #'corfu-quick-exit)

;;; Code:

(require 'corfu)

(defcustom corfu-quick1 "asdfgh"
  "First level quick keys."
  :type 'string
  :group 'corfu)

(defcustom corfu-quick2 "jkl"
  "Second level quick keys."
  :type 'string
  :group 'corfu)

(defface corfu-quick1
  '((((class color) (min-colors 88) (background dark))
     :background "#2a40b8" :weight bold :foreground "white")
    (((class color) (min-colors 88) (background light))
     :background "#77baff" :weight bold :foreground "black")
    (t :background "blue" :foreground "white"))
  "Face used for the first quick key."
  :group 'corfu-faces)

(defface corfu-quick2
  '((((class color) (min-colors 88) (background dark))
     :background "#71206a" :weight bold :foreground "#ffcaf0")
    (((class color) (min-colors 88) (background light))
     :background "#ffccff" :weight bold :foreground "#770077")
    (t :background "magenta" :foreground "white"))
  "Face used for the second quick key."
  :group 'corfu-faces)

(defvar corfu-quick--list nil)
(defvar corfu-quick--first nil)

(defun corfu-quick--keys (idx) ;; See vertico-quick--keys
  "Format keys for IDX."
  (let* ((fst (length corfu-quick1))
         (snd (length corfu-quick2))
         (len (+ fst snd)))
    (if (>= idx fst)
        (let ((first (elt corfu-quick2 (mod (/ (- idx fst) len) snd)))
              (second (elt (concat corfu-quick1 corfu-quick2) (mod (- idx fst) len))))
          (cond
           ((eq first corfu-quick--first)
            (push (cons second (+ corfu--scroll idx)) corfu-quick--list)
            (concat " " (propertize (char-to-string second) 'face 'corfu-quick1)))
           (corfu-quick--first "  ")
           (t
            (push (cons first (list first)) corfu-quick--list)
            (concat (propertize (char-to-string first) 'face 'corfu-quick1)
                    (propertize (char-to-string second) 'face 'corfu-quick2)))))
      (let ((first (elt corfu-quick1 (mod idx fst))))
        (if corfu-quick--first
            "  "
          (push (cons first (+ corfu--scroll idx)) corfu-quick--list)
          (concat (propertize (char-to-string first) 'face 'corfu-quick1) " "))))))

(defun corfu-quick--affixate (cands)
  "Advice for `corfu--affixate' which prefixes the CANDS with quick keys."
  (let ((index 0))
    (dolist (cand cands)
      (setf (cadr cand) (corfu-quick--keys index))
      (cl-incf index))
    cands))

(defun corfu-quick--read (&optional first)
  "Read quick key given FIRST pressed key."
  (cl-letf* ((orig (symbol-function #'corfu--affixate))
             ((symbol-function #'corfu--affixate)
              (lambda (cands)
                (cons nil (corfu-quick--affixate (cdr (funcall orig cands))))))
             (corfu-quick--first first)
             (corfu-quick--list))
    (corfu--candidates-popup (car completion-in-region--data))
    (alist-get (read-key) corfu-quick--list)))

;;;###autoload
(defun corfu-quick-jump ()
  "Jump to candidate using quick keys."
  (interactive)
  (if (= corfu--total 0)
      (and (message "No match") nil)
    (let ((idx (corfu-quick--read)))
      (when (consp idx) (setq idx (corfu-quick--read (car idx))))
      (when idx (setq corfu--index idx)))))

;;;###autoload
(defun corfu-quick-insert ()
  "Insert candidate using quick keys."
  (interactive)
  (when (corfu-quick-jump)
    (corfu-insert)))

;;;###autoload
(defun corfu-quick-complete ()
  "Complete candidate using quick keys."
  (interactive)
  (when (corfu-quick-jump)
    (corfu-complete)))

;; Emacs 28: Do not show Corfu commands in M-X
(dolist (sym '(corfu-quick-jump corfu-quick-insert corfu-quick-complete))
  (put sym 'completion-predicate #'ignore))

(provide 'corfu-quick)
;;; corfu-quick.el ends here

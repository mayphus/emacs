;;; t-mouse.el --- mouse support within the text terminal  -*- lexical-binding:t -*-

;; Author: Nick Roberts <nickrob@gnu.org>
;; Maintainer: emacs-devel@gnu.org
;; Keywords: mouse gpm linux

;; Copyright (C) 1994-1995, 1998, 2006-2025 Free Software Foundation,
;; Inc.

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
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides access to mouse event as reported by the gpm-Linux
;; package.  It tries to reproduce the functionality offered by Emacs under X.
;; The "gpm" server runs under Linux, so this package is rather
;; Linux-dependent.

;; The file, t-mouse.el was originally written by Alessandro Rubini and Ian T
;; Zimmerman, and Emacs communicated with gpm through a client program called
;; mev.  Now the interface with gpm is directly through a Unix socket, so this
;; file is reduced to a single minor mode macro call.

;;

;;; Code:

;; Prevent warning when compiling in an Emacs without gpm support.
(declare-function gpm-mouse-start "term.c" ())

(defun gpm-mouse-enable ()
  "Try to enable gpm mouse support on the current terminal."
  (let ((activated nil))
    (unwind-protect
        (progn
          (unless (fboundp 'gpm-mouse-start)
            (error "Emacs must be built with Gpm to use this mode"))
          (when gpm-mouse-mode
            (gpm-mouse-start)
            (set-terminal-parameter nil 'gpm-mouse-active t)
            (setq activated t)))
      ;; If something failed to turn it on, try to turn it off as well,
      ;; just in case.
      (unless activated (gpm-mouse-disable)))))

(defun gpm-mouse-disable ()
  "Try to disable gpm mouse support on the current terminal."
  (when (fboundp 'gpm-mouse-stop)
    (gpm-mouse-stop))
  (set-terminal-parameter nil 'gpm-mouse-active nil))

(defun gpm-mouse-tty-setup ()
  (if gpm-mouse-mode (gpm-mouse-enable) (gpm-mouse-disable)))

;;;###autoload
(define-minor-mode gpm-mouse-mode
  "Toggle mouse support in GNU/Linux consoles (GPM Mouse mode).

This allows the use of the mouse when operating on a GNU/Linux console,
in the same way as you can use the mouse under X11.
It relies on the `gpm' daemon being activated.

Note that when `gpm-mouse-mode' is enabled, you cannot use the
mouse to transfer text between Emacs and other programs which use
GPM.  This is due to limitations in GPM and the Linux kernel."
  :global t :group 'mouse :init-value t
  (dolist (terminal (terminal-list))
    (when (and (eq t (terminal-live-p terminal))
               (not (eq gpm-mouse-mode
                        (terminal-parameter terminal 'gpm-mouse-active))))
      ;; Simulate selecting a terminal by selecting one of its frames ;-(
      (with-selected-frame (car (frames-on-display-list terminal))
        (gpm-mouse-tty-setup))))
  (when gpm-mouse-mode
    (add-hook 'tty-setup-hook #'gpm-mouse-tty-setup)))

(provide 't-mouse)

;;; t-mouse.el ends here

;;; reply.el --- Reply(light weight Perl REPL) from Emacs

;; Copyright (C) 2013 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL:
;; Version: 0.01

;; This program is free software; you can redistribute it and/or modify
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

;;; Code:

(require 'comint)

(defgroup reply nil
  "Run a reply process in a buffer"
  :group 'perl)

(defcustom inferior-reply-mode-hook nil
  "Hook for customizing inferior-reply mode"
  :type 'hook
  :group 'reply)

;;(defvar inferior-reply-mode-map
;;  (let ((map (make-sparse-keymap)))
;;    (define-key map (kbd "C-c C-r") 'reply-send-region)
;;    (define-key map (kbd "C-c C-z") 'switch-to-reply)
;;    map))

(define-derived-mode inferior-reply-mode comint-mode "Inferior reply"
  "Major mode for interacting with an inferior reply process"
  (setq comint-prompt-regexp "^[0-9]+> *")
  (setq mode-line-process '(":%s"))
  (setq comint-input-filter 'reply--input-filter))

(defcustom inferior-reply-filter-regexp "\\`\\s-+"
  "Regular expression of input filter"
  :type 'regexp
  :group 'reply)

(defvar reply--command "reply")
(defvar reply--buffer nil)
(defvar reply--program-name "reply")

(defun reply--input-filter (str)
  (not (string-match inferior-reply-filter-regexp str)))

(defvar reply--buffer nil)

(defun reply-proc ()
  (unless (and reply--buffer
               (get-buffer reply--buffer)
               (comint-check-proc reply--buffer))
    (reply-interactively-start-process))
  (or (reply--get-process)
      (error "No current process. See variable `reply--buffer'")))

(defun reply--get-process ()
  (let ((buf (if (eq major-mode 'inferior-reply-mode)
                 (current-buffer)
               reply--buffer)))
    (get-buffer-process buf)))

(defun reply-interactively-start-process (&optional _cmd)
  (save-window-excursion
    (run-reply (read-string "Run reply: " reply--program-name))))

;;;###autoload
(defun run-reply (cmd)
  (interactive
   (list (if current-prefix-arg
             (read-string "Run Reply: " reply--command)
           reply--command)))
  (when (not (comint-check-proc "*reply*"))
    (let ((cmdlist (split-string-and-unquote cmd)))
      (set-buffer (apply 'make-comint "reply" (car cmdlist) nil
                         (cdr cmdlist)))
      (inferior-reply-mode)))
  (setq reply--program-name cmd)
  (setq reply--buffer "*reply*")
  (pop-to-buffer-same-window "*reply*"))

(defun switch-to-reply (eob-p)
  (interactive "P")
  (if (or (and reply--buffer (get-buffer reply--buffer))
          (reply-interactively-start-process))
      (pop-to-buffer-same-window reply--buffer)
    (error "No current process buffer. See variable `reply--buffer'"))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

(defsubst reply--remove-newlines (str)
  (replace-regexp-in-string "\r?\n?$" " " str))

(defun reply-send-region (start end)
  (interactive "r")
  (let ((str (buffer-substring-no-properties start end)))
    (comint-send-string (reply-proc) (reply--remove-newlines str))
    (comint-send-string (reply-proc) "\n")))

(defun reply-send-region-and-go (start end)
  (interactive "r")
  (reply-send-region start end)
  (switch-to-reply t))

(provide 'reply)

;;; reply.el ends here

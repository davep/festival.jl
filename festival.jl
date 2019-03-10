;;; festival.jl --- sawfish interface into festival.
;; Copyright 1999,2000 by Dave Pearson <davep@davep.org>
;; $Revision: 1.3 $

;; festival.jl is free software distributed under the terms of the GNU
;; General Public Licence, version 2. For details see the file COPYING.

;;; Commentary:
;;
;; The following code turns sawfish into a speaking window manager when
;; combined with <URL:http://www.cstr.ed.ac.uk/projects/festival.html>.
;;
;; Drop this file into your sawfish load-path and from a sawfish-client (or
;; in your ~/.sawfishrc) issue:
;;
;; (require 'festival)
;; (festival-open)
;;
;; To make festival read the name of a workspace when you change to it
;; issue:
;;
;; (festival-say-workspace-on-change t)
;;
;; To get sawfish to waffle on about windows when you change focus use:
;;
;; (festival-say-window-on-focus t)
;;
;; You can turn the speech off at any time (probably within the first 30
;; seconds of use <g>) with:
;;
;; (festival-close)
;;
;; Note that `festival-open' and `festival-close' are interactive functions
;; (IOW "commands") so you can bind them to a key.
;;
;; The function `festival-say' can be used to pass any text to festival so
;; feel free to add more speech abilities to your sawfish environment.

;;; Code:

;; Things we need:

(require 'keymap)

;; Customise options.

(defgroup festival "Speech synthesis")

(defcustom festival-client "festival"
  "Client application for talking to festival."
  :group     festival
  :type      string
  :allow-nil nil)

(defcustom festival-client-arg-list "(\"--pipe\")"
  "Argument list to pass to the festival client."
  :group     festival
  :type      string
  :allow-nil nil)

;; Non-customisable variables.

(defvar festival-process nil
  "Holds the handle to the sawfish process.")

;; Main code:

(defun festival-open ()
  "Open a festival session."
  (interactive)
  (unless (processp festival-process)
    (setq festival-process (make-process))
    (set-process-prog festival-process festival-client)
    (set-process-args festival-process (read-from-string festival-client-arg-list))
    (start-process festival-process))
  festival-process)

(defun festival-close ()
  "Close a festival session."
  (interactive)
  (when (processp festival-process)
    (when (process-running-p festival-process)
      (kill-process festival-process))
    (setq festival-process nil)))

(defun festival-running-p ()
  "Is there a festival process up and running?"
  (and (processp festival-process) (process-running-p festival-process)))

(defun festival-eval (sexp)
  "Send SEXP to the festival process."
  (when (festival-running-p)
    (print sexp festival-process)))

(defun festival-say (text)
  "Say some text.

For this function to work you must have first called `festival-open' to
create the connection with the festival speech synthesizer."
  (festival-eval `(SayText ,text)))

(defun festival-say-workspace ()
  "Say the name of the current workspace."
  (interactive)
  (festival-say (or (nth current-workspace workspace-names)
                    (format nil "Workspace %d" current-workspace))))

(defun festival-say-window (w)
  "Say the name of window W."
  (interactive "%W")
  (festival-say (window-name w)))

(defun festival-say-current-window ()
  "Say the name of the current window."
  (interactive)
  (festival-say-window (input-focus)))

(defun festival-say-workspace-on-change (enable)
  "Enable/disable the reading of a workspace's name when you change to it."
  (if enable
      (unless (in-hook-p 'enter-workspace-hook festival-say-workspace)
        (add-hook 'enter-workspace-hook festival-say-workspace))
    (remove-hook 'enter-workspace-hook festival-say-workspace)))

(defun festival-say-window-on-focus (enable)
  "Enable/disable the reading of a window's name when it receives focus."
  (if enable
      (unless (in-hook-p 'focus-in-hook festival-say-window)
        (add-hook 'focus-in-hook festival-say-window))
    (remove-hook 'focus-in-hook festival-say-window)))

(defun festival-describe-key ()
  "Speak the output of `describe-key'."
  (interactive)
  (festival-say (let ((standard-output (make-string-output-stream)))
                  (describe-key)
                  (get-output-stream-string standard-output))))
  
(defun festival-voice-english-male ()
  "Choose a male English voice.

Note that you must have everything required for this voice installed for
this to work. No checking is done by this function."
  (interactive)
  (festival-eval '(voice.select (quote rab_diphone))))

(defun festival-voice-US-male ()
  "Choose a male US voice.

Note that you must have everything required for this voice installed for
this to work. No checking is done by this function."
  (interactive)
  (festival-eval '(voice.select (quote ked_diphone))))

(provide 'festival)

;;; festival.jl ends here

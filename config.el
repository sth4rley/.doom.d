;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; you do not need to run 'doom sync' after modifying this file!

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they accept.


(setq doom-font (font-spec :family "CaskaydiaMono Nerd Font Mono" :size 17 :weight 'SemiBold)) ;; SPC h r f -> reload font

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-sourcerer)

(setq display-line-numbers-type 'relative)


(setq org-directory "~/org/")



;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


(after! org
  ;;(setq org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "|" "DONE" "CANCELLED(c)")))
  (setq
   org-superstar-headline-bullets-list '("✱") ;;🟂🟄✦❖🞛✱🞴◆
   org-superstar-item-bullet-alist '((?* . ?*)
                                     (?- . ?⮡)
                                     (?+ . ?⬥)))
  ;;(require 'org-download)
  ;;   (setq-default org-download-heading-lvl nil)
  ;;   (setq-default org-download-image-dir "./images")



  (custom-set-faces
   ;; '(org-superstar-header-bullet ((t (:height 1.0))))
   ;; '(org-level-1 ((t (:inherit outline-1 :height 1.3))))
   ;;'(org-level-2 ((t (:inherit outline-2 :height 1.2))))
   ;;'(org-level-3 ((t (:inherit outline-3 :height 1.15))))
   ;;'(org-level-4 ((t (:inherit outline-4 :height 1.1))))
   )

  )


(after! doom-modeline
  (setq doom-modeline-check-simple-format t)
  (setq doom-modeline-icon t)
  ;;(setq doom-modeline-battery t)
  ;;(setq doom-modeline-time t)
  ;;(setq doom-modeline-workspace-name t)
  ;;(setq doom-modeline-position-column-line-format '("%l:%c"))

  (setq doom-modeline-lsp t)
  (setq doom-modeline-hud t)
  (setq doom-modeline-env-version t)

  ;; An evil mode indicator is redundant with cursor shape
  (setq doom-modeline-modal nil)

  )


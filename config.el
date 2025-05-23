;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-tomorrow-night)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15))
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")
(setq evil-split-window-below t evil-vsplit-window-right t)

(add-to-list 'default-frame-alist '(inhibit-double-buffering . t)) ;; prevent some cases of flickering
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(fset 'rainbow-delimiters-mode #'ignore) ;; disable rainbow delimiters 💅
(setq doom-scratch-initial-major-mode 'org-mode) ;; scratch buffer org mode

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


(after! doom-modeline
  (setq doom-modeline-modal nil) ;; an evil mode indicator is redundant with cursor shape
  (setq doom-modeline-check-simple-format t)
  (setq doom-modeline-env-version t)
  )


(use-package copilot-chat
  :bind (:map global-map
              ("C-c C-." . copilot-chat-transient)
              ("C-c C-y" . copilot-chat-yank)
              ("C-c M-y" . copilot-chat-yank-pop)
              ("C-c C-M-y" . (lambda () (interactive) (copilot-chat-yank-pop -1)))
              ("C-c C-c" . copilot-chat))
  )

(add-hook 'git-commit-setup-hook 'copilot-chat-insert-commit-message)
(setq copilot-chat-follow t)

(add-to-list 'display-buffer-alist
             '("\\*Copilot Chat.*"
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . right) (slot . 1) (window-width . 0.4))) ;; 40% de largura

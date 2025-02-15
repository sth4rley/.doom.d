;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-ir-black)
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

(after! doom-modeline
  (setq doom-modeline-modal nil) ;; an evil mode indicator is redundant with cursor shape
  (setq doom-modeline-check-simple-format t)
  (setq doom-modeline-env-version t)
)

;;(after! lsp-mode
;;  (setq lsp-enable-symbol-highlighting nil)
  ;; If an LSP server isn't present when I start a prog-mode buffer, you
  ;; don't need to tell me. I know. On some machines I don't care to have
  ;; a whole development environment for some ecosystems.
;;  (setq lsp-enable-suggest-server-download nil)
;;)

;;(after! lsp-ui
;;  (setq lsp-ui-doc-enable nil) ;; redundant with K
;;  (setq lsp-ui-sideline-enable nil) ;; no more useuful than flycheck
;;)

(use-package! lsp-bridge
  :config
  (setq lsp-bridge-enable-log nil)
  (setq lsp-bridge-enable-hover-diagnostic t)
  (setq lsp-bridge-python-command "/usr/bin/python3")
  (global-lsp-bridge-mode)
  )

(use-package! copilot
  ;;:hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)
              ("C-n" . 'copilot-next-completion)
              ("C-p" . 'copilot-previous-completion)
              ("C-j" . 'copilot-accept-completion))
  :config
  (map! :leader
        :desc "Toggle Copilot Mode" "t c" #'copilot-mode))

(use-package copilot-chat
  :bind (:map global-map
        ("C-c C-." . copilot-chat-transient)
        ("C-c C-y" . copilot-chat-yank)
            )
)

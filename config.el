;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-1337
      doom-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 15)
      doom-variable-pitch-font (font-spec :family "DejaVu Sans" :size 20))

;; Line numbers are pretty slgw all around. The performance boost of disabling
;; them outweighs the utility of always keeping them on.
(setq display-line-numbers-type nil)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

(setq fancy-splash-image (file-name-concat doom-user-dir "cacochan.png"))

;; Hide the menu for as minimalistic a startup screen as possible.
;; (setq +doom-dashboard-functions '(doom-dashboard-widget-banner))

;; scratch buffer org mode
(setq doom-scratch-initial-major-mode 'org-mode)

;;; :editor evil
;; Focus new window after splitting
(setq evil-split-window-below t
      evil-vsplit-window-right t)

;; Prevents some cases of Emacs flickering.
(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))

(fset 'rainbow-delimiters-mode #'ignore)


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
;; To get information about any of these functions/macros press 'K' This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces, etc).
;; You can also try 'gd' to jump to their definition and see how they are implemented.


(after! doom-modeline
  (setq doom-modeline-check-simple-format t)
  (setq doom-modeline-env-version t)
  ;; An evil mode indicator is redundant with cursor shape
  (setq doom-modeline-modal nil)
  )

(after! lsp-mode
  (setq lsp-enable-symbol-highlighting nil
        ;; If an LSP server isn't present when I start a prog-mode buffer, you
        ;; don't need to tell me. I know. On some machines I don't care to have
        ;; a whole development environment for some ecosystems.
        lsp-enable-suggest-server-download nil
        )
  )

(after! lsp-ui
  (setq lsp-ui-doc-enable nil ; redundant with K
        lsp-ui-sideline-enable nil  ; no more useful than flycheck
        )
  )

;; packages
(use-package! devdocs
  :config
  (map! :leader "d d" #'devdocs-lookup)
  (map! :leader "d s" #'devdocs-peruse)
  )

(add-to-list 'initial-frame-alist '(fullscreen . maximized))

(use-package! copilot
  :hook ((prog-mode . copilot-mode)       
         (org-mode . (lambda () (copilot-mode -1)))) 

  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

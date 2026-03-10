;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-sourcerer)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15))
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")
(setq evil-split-window-below t evil-vsplit-window-right t)
(setq shell-file-name (executable-find "bash"))

(add-to-list 'default-frame-alist '(inhibit-double-buffering . t)) ;; prevent some cases of flickering
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
;;(fset 'rainbow-delimiters-mode #'ignore) ;; disable rainbow delimiters 💅
(setq doom-scratch-initial-major-mode 'org-mode) ;; scratch buffer org mode

;;(setq scroll-step 1
;;      scroll-margin 3
;;      scroll-conservatively 101)

;;(setq pixel-scroll-precision-use-momentum t)
;;(pixel-scroll-precision-mode 1)


(setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil) ;; desativa aceleração
(setq scroll-conservatively 101)
(setq scroll-margin 3)


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


(use-package! copilot-chat) ;; We define bindings below using the map! macro

;; (add-hook 'git-commit-setup-hook #'copilot-chat-insert-commit-message)

(after! copilot-chat
  (setq copilot-chat-follow t)
  (setq copilot-chat-commit-prompt
        (concat
         "Escreva uma mensagem de commit em português (pt-BR), no padrão Conventional Commits. "
         "Use este formato: tipo(escopo opcional): resumo no imperativo e em minúsculas. "
         "Tipos permitidos: feat, fix, docs, style, refactor, test, chore, perf, build, ci. "
         "Se útil, inclua corpo curto (1-3 linhas) explicando o porquê da mudança. "
         "Não invente mudanças; use apenas o diff disponível. "
         "Retorne apenas a mensagem de commit final, sem markdown e sem explicações."))
  (set-popup-rule! "^\*Copilot Chat.*"
    :side 'right      ; Exibir no lado direito
    :size 0.33        ; Ocupar 33% da largura do frame
    :select t         ; Selecionar automaticamente a janela quando ela abrir
    :quit t           ; Torná-la "quit-able" (essencial para o ESC)
    :ttl nil))        ; Não fechar automaticamente (time-to-live)

;; accept completion from copilot and fallback to company
;; acredito que eu não esteja usando o company, mas sim o corfu (verificar em init.el)
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . #'copilot-accept-completion)
              ("C-<tab>" . #'copilot-accept-completion-by-word))
  :config
  ;; Fix for "copilot--infer-indentation-offset found no mode-specific indentation offset"
  (setq copilot-indentation-offset 2))

;;; Standardized Copilot Keybindings
(map! :leader
      :prefix ("z" . "Copilot") ;; SPC z
      ;; Chat Commands
      "c" #'copilot-chat
      "b" #'copilot-chat-chat-buffer
      "r" #'copilot-chat-chat-region
      ;; Yank Commands
      "y" #'copilot-chat-yank
      "Y" #'copilot-chat-yank-pop)

;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-sourcerer)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15))
;; fonte proporcional, usada no texto do markdown renderizado
;; (Adwaita Sans: derivada da Inter, desenhada para leitura em tela)
(setq doom-variable-pitch-font (font-spec :family "Adwaita Sans"))
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


;;; Web
;; templates Jinja do Flask (pastas templates*/): o motor django do web-mode
;; entende {% %} e {{ }}
(after! web-mode
  (add-to-list 'web-mode-engines-alist '("django" . "templates[^/]*/.+\\.html?\\'")))


;;; Markdown
;; .md abre renderizado no próprio buffer (markdown-modern): títulos com tamanhos
;; diferentes, tabelas desenhadas e ajustadas à janela, sem a marcação visível.
;; O elemento sob o cursor mostra o markdown cru para editar.
(defun my/markdown-toggle-rendering ()
  "Alterna entre o markdown renderizado (markdown-modern) e o fonte puro (markdown-mode)."
  (interactive)
  (if (derived-mode-p 'markdown-modern-mode)
      (markdown-mode)
    (markdown-modern-mode)))

(defun my/markdown-outline-search (&optional bound move backward looking-at)
  "Busca títulos markdown para o `outline', pulando `#' dentro de blocos de código."
  (let ((re "^\\(#\\{1,6\\}\\)[ \t]"))
    (if looking-at
        (and (looking-at re)
             (not (save-match-data (markdown-modern--fenced-code-block-at (point)))))
      (let ((orig (point)) found)
        (while (and (not found)
                    (if backward
                        (re-search-backward re bound t)
                      (re-search-forward re bound t)))
          (unless (save-match-data
                    (markdown-modern--fenced-code-block-at (match-beginning 0)))
            (setq found t)))
        (cond (found t)
              (move (goto-char (or bound (if backward (point-min) (point-max)))) nil)
              (t (goto-char orig) nil))))))

(defun my/markdown-fold-cycle ()
  "No título: dobra/desdobra como o TAB do org. Fora dele não faz nada (nunca insere texto)."
  (interactive)
  (when (outline-on-heading-p)
    (outline-cycle)))

(defvar my/markdown-column-width 120
  "Largura, em colunas, do texto do markdown renderizado (centralizado na janela).")

(defun my/markdown-center-column-h (&optional win)
  "Põe margens iguais dos dois lados da janela, deixando o texto numa coluna central."
  (let ((win (if (windowp win) win (get-buffer-window nil t))))
    (when (window-live-p win)
      (let* ((margins (window-margins win))
             (text (+ (window-body-width win) (or (car margins) 0) (or (cdr margins) 0)))
             (side (max 0 (/ (- text my/markdown-column-width) 2))))
        (unless (equal margins (cons side side))
          (set-window-margins win side side)
          ;; as tabelas são dimensionadas pela largura da janela: redesenha
          (with-current-buffer (window-buffer win) (jit-lock-refontify)))
        ;; bordas (fringes) entre a margem e o texto, não na beira da janela:
        ;; as marcas delas (texto apagado, git) ficam junto do texto
        (when (nth 2 (window-fringes win))
          (set-window-fringes win nil nil nil))))))

(defvar my/markdown-heading-space '((1 . 1.2) (2 . 0.5) (3 . 0.3))
  "Espaço extra acima dos títulos, por nível, em alturas de linha.
Níveis fora da lista não ganham espaço.")

(defvar my/markdown-top-space 2.4
  "Altura da primeira linha do documento, em múltiplos da altura do título.
O que passa da altura do título vira a margem do topo.")

(defvar-local my/markdown-refresh-timer nil)

(defun my/markdown-heading-space-refresh (&optional buf)
  "Põe um espaço acima de cada título, maior quanto mais alto o nível, e a
margem do topo do documento.
Vale com a seção aberta ou dobrada: na lista de títulos dobrados funciona
como um padding entre eles.  Nada disso é uma linha extra antes do título:
como a marcação `## ' fica escondida no começo da linha, uma linha extra ali
fazia o cursor ser desenhado no título de cima e o TAB abrir o de baixo."
  (with-current-buffer (or buf (current-buffer))
    (remove-overlays (point-min) (point-max) 'my/markdown-heading-space t)
    (save-excursion
      ;; margem do topo: a primeira linha na tela fica mais alta (o excesso do
      ;; line-height vai para cima do texto); com o título dobrado, essa linha
      ;; termina na primeira quebra de linha visível depois dele
      (goto-char (point-min))
      (if (looking-at "#\\{1,6\\}[ \t]")
          (let ((nl (line-end-position)))
            (while (and (< nl (point-max)) (invisible-p nl))
              (setq nl (next-single-char-property-change nl 'invisible)))
            (when (< nl (point-max))
              (let ((ov (make-overlay nl (1+ nl))))
                (overlay-put ov 'my/markdown-heading-space t)
                (overlay-put ov 'line-height (cons nil my/markdown-top-space)))))
        ;; documento que não começa com título: uma linha vazia antes dele
        (let ((ov (make-overlay (point-min) (point-min))))
          (overlay-put ov 'my/markdown-heading-space t)
          (overlay-put ov 'before-string (propertize "\n" 'face '(:height 2.5)))))
      (while (re-search-forward "^\\(#\\{1,6\\}\\)[ \t]" nil t)
        (let ((ratio (alist-get (length (match-string 1)) my/markdown-heading-space))
              (bol (match-beginning 0)))
          ;; o espaço fica embaixo da linha anterior (line-spacing na quebra de
          ;; linha antes do título), não numa linha extra: com uma linha extra
          ;; o cursor era desenhado no título de cima e o TAB abria o de baixo
          (when (and ratio
                     (> bol (point-min))
                     (not (save-match-data (markdown-modern--fenced-code-block-at bol))))
            (let ((ov (make-overlay (1- bol) bol)))
              (overlay-put ov 'my/markdown-heading-space t)
              (overlay-put ov 'line-spacing ratio))))))))

(defun my/markdown-refresh-schedule-h (&rest _)
  "Recalcula o espaço dos títulos e o destaque das anotações para o Claude
logo depois de uma edição ou dobra."
  (when (derived-mode-p 'markdown-modern-mode)
    (when (timerp my/markdown-refresh-timer)
      (cancel-timer my/markdown-refresh-timer))
    (setq my/markdown-refresh-timer
          (run-with-timer 0.1 nil (lambda (buf)
                                    (when (buffer-live-p buf)
                                      (my/markdown-heading-space-refresh buf)
                                      (my/markdown-claude-notes-refresh buf)))
                          (current-buffer)))))

(defun my/markdown-remove-decorations-h ()
  "Tira os overlays desta configuração (ao trocar para o fonte puro com SPC m m)."
  (dolist (prop '(my/markdown-heading-space my/markdown-claude-note my/markdown-change))
    (remove-overlays (point-min) (point-max) prop t)))

(defun my/markdown-reveal-point ()
  "Abre a seção dobrada em que o cursor caiu."
  (when (invisible-p (point))
    (outline-show-entry)))

;; seção atual no topo da janela: o caminho de títulos até o cursor, como
;; "Parte A › A3. Os impostos", para não se perder rolando uma spec longa
(defface my/markdown-breadcrumb '((t :inherit (variable-pitch shadow) :height 0.9))
  "Caminho de títulos mostrado no topo da janela do markdown.")

(defvar-local my/markdown-breadcrumb-cache nil
  "Último caminho calculado, como ((TICK . PONTO) . TEXTO).")

(defun my/markdown-heading-title ()
  "Texto do título da linha atual, sem os `#' e sem a marcação inline."
  (let ((s (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (pcase-dolist (`(,re . ,rep) '(("\\`#+[ \t]+" . "")
                                   ("[ \t]+#+[ \t]*\\'" . "")
                                   ("\\[\\([^]]*\\)\\]([^)]*)" . "\\1")
                                   ("\\*\\*\\|__\\|`" . "")))
      (setq s (replace-regexp-in-string re rep s)))
    s))

(defun my/markdown-breadcrumb ()
  "Caminho de títulos até a seção do cursor (calculado de novo só quando o
cursor ou o texto mudam)."
  (let ((key (cons (buffer-chars-modified-tick) (point))))
    (unless (equal key (car my/markdown-breadcrumb-cache))
      (setq my/markdown-breadcrumb-cache
            (cons key
                  (save-excursion
                    (save-match-data
                      (when (ignore-errors (outline-back-to-heading t) t)
                        (let ((path (list (my/markdown-heading-title))))
                          (while (ignore-errors (outline-up-heading 1 t) t)
                            (push (my/markdown-heading-title) path))
                          (string-join path "  ›  "))))))))
    (cdr my/markdown-breadcrumb-cache)))

(defun my/markdown-breadcrumb-setup-h ()
  "Mostra o caminho de títulos no topo, com o fundo do texto e um respiro."
  (setq-local header-line-format
              '((:eval (when-let* ((path (my/markdown-breadcrumb)))
                         (concat (propertize " " 'display '(space :align-to 0))
                                 (propertize path 'face 'my/markdown-breadcrumb))))))
  (let ((bg (face-background 'default nil t)))
    (face-remap-add-relative 'header-line
                             `(:background ,bg :box (:line-width (0 . 8) :color ,bg)
                               :underline nil :overline nil))))

;; o que mudou no arquivo fora do Emacs (o Claude editando a spec) fica com o
;; fundo destacado até o ESC; onde só saiu texto, uma seta na borda esquerda
(defface my/markdown-change '((t :inherit highlight :extend t))
  "Linhas que mudaram no arquivo fora do Emacs.")

(defface my/markdown-change-removed '((t :inherit error))
  "Seta na borda onde saiu texto do arquivo sem entrar nada no lugar.")

(custom-set-faces!
  `(my/markdown-change
    :background ,(or (ignore-errors (doom-blend (doom-color 'green) (doom-color 'bg) 0.2))
                     'unspecified)
    :extend t))

(defvar-local my/markdown-text-before-revert nil
  "Texto do buffer antes do recarregamento, para comparar com o novo.")

(defun my/markdown-save-text-h ()
  "Guarda o texto de antes do recarregamento."
  (setq my/markdown-text-before-revert
        (buffer-substring-no-properties (point-min) (point-max))))

(defun my/markdown-show-changes-h ()
  "Destaca as linhas que o recarregamento mudou, comparando com `diff' o
texto de antes e o de agora."
  (when-let* ((old (prog1 my/markdown-text-before-revert
                     (setq my/markdown-text-before-revert nil))))
    (let* ((coding-system-for-write 'utf-8-unix)
           (coding-system-for-read 'utf-8-unix)
           (file (make-temp-file "markdown-antes" nil ".md"))
           hunks)
      (write-region old nil file nil 'silent)
      (unwind-protect
          (let ((out (generate-new-buffer " *markdown-diff*")))
            (unwind-protect
                (progn
                  (call-process-region (point-min) (point-max) "diff" nil out nil "-U0" file "-")
                  (with-current-buffer out
                    (goto-char (point-min))
                    ;; @@ -antes +INÍCIO,QUANTAS @@ (linhas no texto novo)
                    (while (re-search-forward "^@@ -[0-9,]+ \\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? @@" nil t)
                      (push (cons (string-to-number (match-string 1))
                                  (if (match-string 2) (string-to-number (match-string 2)) 1))
                            hunks))))
              (kill-buffer out)))
        (delete-file file))
      (save-excursion
        (pcase-dolist (`(,line . ,count) hunks)
          (goto-char (point-min))
          (if (> count 0)
              (let ((ov (make-overlay (progn (forward-line (1- line)) (point))
                                      (progn (forward-line count) (point))
                                      nil t nil)))
                (overlay-put ov 'my/markdown-change t)
                (overlay-put ov 'face 'my/markdown-change))
            ;; só saiu texto: a seta fica na linha logo depois do que saiu
            (forward-line line)
            (let ((ov (make-overlay (point) (point))))
              (overlay-put ov 'my/markdown-change t)
              (overlay-put ov 'before-string
                           (propertize "-" 'display '(left-fringe right-triangle my/markdown-change-removed))))))))))

(defun my/markdown-clear-changes-h ()
  "ESC tira o destaque das mudanças que vieram de fora."
  (when (and (derived-mode-p 'markdown-modern-mode)
             (seq-some (lambda (o) (overlay-get o 'my/markdown-change))
                       (overlays-in (point-min) (point-max))))
    (remove-overlays (point-min) (point-max) 'my/markdown-change t)
    t))

(defun my/markdown-next-change (&optional back)
  "Vai para a próxima mudança destacada (com BACK, para a anterior)."
  (interactive)
  (let* ((starts (sort (delete-dups
                        (mapcar #'overlay-start
                                (seq-filter (lambda (o) (overlay-get o 'my/markdown-change))
                                            (overlays-in (point-min) (point-max)))))
                       #'<))
         (target (if back
                     (car (last (seq-filter (lambda (p) (< p (line-beginning-position))) starts)))
                   (seq-find (lambda (p) (> p (line-end-position))) starts))))
    (if (not target)
        (message "Nenhuma outra mudança destacada")
      (goto-char target)
      (my/markdown-reveal-point))))

(defun my/markdown-previous-change ()
  "Vai para a mudança destacada anterior."
  (interactive)
  (my/markdown-next-change t))

;; anotações de revisão para o Claude: <!-- @claude: ... --> no meio da spec,
;; destacadas; depois é só pedir ao Claude "resolva as anotações @claude"
(defface my/markdown-claude-note '((t :inherit font-lock-warning-face :slant italic))
  "Anotação para o Claude no meio da spec.")

(defconst my/markdown-claude-note-re "<!--[ \t\n]*@claude\\(?:.\\|\n\\)*?-->"
  "Anotação para o Claude: um comentário HTML que começa com @claude.")

(defun my/markdown-claude-notes-refresh (&optional buf)
  "Destaca as anotações para o Claude."
  (with-current-buffer (or buf (current-buffer))
    (remove-overlays (point-min) (point-max) 'my/markdown-claude-note t)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward my/markdown-claude-note-re nil t)
        (let ((ov (make-overlay (match-beginning 0) (match-end 0))))
          (overlay-put ov 'my/markdown-claude-note t)
          (overlay-put ov 'face 'my/markdown-claude-note))))))

(defun my/markdown-claude-note-insert ()
  "Abre uma anotação para o Claude numa linha nova abaixo do cursor."
  (interactive)
  (end-of-line)
  (insert "\n<!-- @claude:  -->")
  (backward-char 4)
  (when (bound-and-true-p evil-local-mode)
    (evil-insert-state)))

(defun my/markdown-claude-note-next (&optional back)
  "Vai para a próxima anotação para o Claude (com BACK, para a anterior)."
  (interactive)
  (let ((pos (save-excursion
               (if back
                   (progn (beginning-of-line)
                          (re-search-backward "<!--[ \t\n]*@claude" nil t))
                 (end-of-line)
                 (and (re-search-forward "<!--[ \t\n]*@claude" nil t)
                      (match-beginning 0))))))
    (if (not pos)
        (message "Nenhuma outra anotação @claude")
      (goto-char pos)
      (my/markdown-reveal-point))))

(defun my/markdown-claude-note-previous ()
  "Vai para a anotação para o Claude anterior."
  (interactive)
  (my/markdown-claude-note-next t))

(defun my/markdown-claude-note-list ()
  "Lista as anotações para o Claude da spec, para pular para uma delas."
  (interactive)
  (consult-line "@claude"))

(use-package! markdown-modern
  :mode ("\\.md\\'" . markdown-modern-mode)
  :config
  ;; sem números de linha no markdown renderizado: numa tabela cada linha do
  ;; arquivo ocupa várias linhas na tela e o número caía na borda, não no texto
  ;; (SPC t l liga de volta no buffer atual)
  (add-hook 'markdown-modern-mode-hook #'doom-disable-line-numbers-h)

  ;; texto numa coluna central com margens iguais dos dois lados; sem o recuo
  ;; de 4 espaços que o pacote põe só à esquerda
  (setq markdown-modern-left-margin 0)
  (add-hook! 'markdown-modern-mode-hook
    (add-hook 'window-size-change-functions #'my/markdown-center-column-h nil t)
    (add-hook 'window-buffer-change-functions #'my/markdown-center-column-h nil t)
    (my/markdown-center-column-h))
  ;; margem do topo e espaço acima dos títulos (nível 1 > 2 > 3), para cada
  ;; seção começar visivelmente; recalculado ao editar e ao dobrar/desdobrar
  (add-hook! 'markdown-modern-mode-hook
    (my/markdown-heading-space-refresh)
    (my/markdown-claude-notes-refresh)
    (add-hook 'after-change-functions #'my/markdown-refresh-schedule-h nil t)
    (add-hook 'change-major-mode-hook #'my/markdown-remove-decorations-h nil t))
  (advice-add 'outline-flag-region :after #'my/markdown-refresh-schedule-h)

  (add-hook 'markdown-modern-mode-hook #'my/markdown-breadcrumb-setup-h)

  ;; o recarregamento troca só os trechos que mudaram (em vez de tudo entre a
  ;; primeira e a última mudança, o que abria as dobras do meio), e cada
  ;; trecho fica destacado
  (add-hook! 'markdown-modern-mode-hook
    (setq-local revert-buffer-insert-file-contents-function
                #'revert-buffer-insert-file-contents-delicately)
    (add-hook 'before-revert-hook #'my/markdown-save-text-h nil t)
    (add-hook 'after-revert-hook #'my/markdown-show-changes-h nil t))
  (add-hook 'doom-escape-hook #'my/markdown-clear-changes-h)

  ;; com variable-pitch, os números de linha herdam a fonte proporcional e as
  ;; linhas sem número (bordas e células das tabelas) ficam deslocadas
  (add-hook! 'markdown-modern-mode-hook
    (face-remap-add-relative 'line-number 'fixed-pitch)
    (face-remap-add-relative 'line-number-current-line 'fixed-pitch))

  ;; a largura das tabelas não desconta a coluna de números de linha, então as
  ;; mais largas transbordavam a janela
  (defadvice! my/markdown-modern-table-width-a (cols)
    :filter-return #'markdown-modern-render--table-display-width
    (if-let* ((win (get-buffer-window)))
        (max 20 (- cols (ceiling (line-number-display-width t)
                                 (window-font-width win 'markdown-modern-table))))
      cols))

  ;; só mostra o markdown cru do elemento sob o cursor no modo de inserção;
  ;; no normal (lendo/navegando) tabelas, títulos e ênfases continuam renderizados
  (defadvice! my/markdown-modern-reveal-only-insert-a (fn pos)
    :around #'markdown-modern--markup-element-at
    (when (or (not (bound-and-true-p evil-local-mode))
              (memq evil-state '(insert replace emacs)))
      (funcall fn pos)))

  ;; bug do pacote: ao redesenhar um item de lista ele apaga só o item, mas
  ;; redesenha a lista inteira, e as bolinhas dos outros itens se acumulavam;
  ;; aqui a área apagada passa a cobrir tudo o que vai ser redesenhado
  (defadvice! my/markdown-modern-clear-whole-elements-a (fn start end)
    :around #'markdown-modern-render--render-region
    (when (and (not markdown-modern-render--rendering-p) markdown-modern--rendering-enabled)
      (dolist (el (markdown-modern-ts--elements-in-region start end))
        (setq start (min start (markdown-modern-node-start el))
              end (max end (markdown-modern-node-end el)))))
    (funcall fn start end))

  ;; com a marcação escondida (`## ' vira display ""), o Emacs empurra o cursor
  ;; para a linha de cima ao subir para um título, e ele caía na seção anterior
  (setq-hook! 'markdown-modern-mode-hook global-disable-point-adjustment t)

  ;; fold de seções como no org: o outline do Emacs passa a reconhecer os títulos
  ;; markdown, e os atalhos do módulo fold do Doom (za, zo, zc, zM, zR) funcionam
  (add-hook! 'markdown-modern-mode-hook
    (setq-local outline-regexp "#\\{1,6\\}[ \t]"
                outline-search-function #'my/markdown-outline-search
                outline-level (lambda () (save-excursion (forward-line 0) (skip-chars-forward "#"))))
    (outline-minor-mode +1)
    ;; ao recarregar o arquivo, as dobras ficam como estavam (só o trecho
    ;; alterado é trocado); o restaurador do outline fecharia cada seção
    ;; dobrada junto com os subtítulos, e a lista de títulos perderia os subtítulos
    (remove-hook 'revert-buffer-restore-functions #'outline-revert-buffer-restore-visibility t))

  ;; arquivo alterado fora do Emacs (o Claude Code editando a spec) aparece na
  ;; hora, mesmo com o foco no terminal; o Doom só recarrega ao voltar para o
  ;; Emacs ou trocar de buffer. Com alterações não salvas, não recarrega.
  (add-hook! 'markdown-modern-mode-hook
    (setq-local auto-revert-use-notify t)
    (auto-revert-mode +1))

  (map! :map markdown-modern-mode-map
        :n "TAB"     #'my/markdown-fold-cycle   ;; título: fechado -> subtítulos -> tudo
        :n [backtab] #'outline-cycle-buffer     ;; documento todo: títulos de topo -> todos os títulos -> tudo
        :m "]h"      #'markdown-modern-next-heading
        :m "[h"      #'markdown-modern-prev-heading
        :n "]m"      #'my/markdown-next-change           ;; mudanças vindas de fora
        :n "[m"      #'my/markdown-previous-change
        :n "]c"      #'my/markdown-claude-note-next      ;; anotações @claude
        :n "[c"      #'my/markdown-claude-note-previous
        :localleader
        "c" #'my/markdown-claude-note-insert          ;; SPC m c: anotação para o Claude
        "C" #'my/markdown-claude-note-list            ;; SPC m C: lista as anotações
        "m" #'my/markdown-toggle-rendering            ;; SPC m m: fonte puro <-> renderizado
        "e" #'markdown-modern-toggle-element-at-point ;; mostra/esconde o cru do elemento
        "'" #'markdown-modern-edit-code-block
        "w" #'markdown-modern-toggle-truncate-lines)) ;; rolagem horizontal em vez de quebrar

(after! markdown-mode
  (map! :map markdown-mode-map
        :localleader
        "m" #'my/markdown-toggle-rendering))

#!/bin/bash

PLAYER_SIGN='X'
TURN_OF='X'

GAME_STATE='         ' # каждая позиция - состояние клетки игры
NEED_TO_REPAINT=true

run_game() {
    trap 'rm game_pipe; reset' EXIT

    if [[ -e game_pipe ]]
        then connect_second
        else
            mkfifo game_pipe &>/dev/null
            connect_first
    fi

    while true; do
        if [[ $NEED_TO_REPAINT = true ]]; then
            repaint_game_desk
            NEED_TO_REPAINT=false
        fi

        if [[ $PLAYER_SIGN = $TURN_OF ]]
            then make_move
            else wait_enemy_move
        fi

        check_endof_game
    done
}

connect_first() {
    echo 'Ждем второго игрока'
    PLAYER_SIGN=`get_first_player_sign`
    echo `get_enemy_sign` > game_pipe
}

connect_second() {
    PLAYER_SIGN=`cat game_pipe`
}

get_first_player_sign() {
    rand=`shuf -i 0-1 -n 1`

    if [[ $rand = 0 ]]
        then echo 'X'
        else echo 'O'
    fi
}

get_enemy_sign() {
    if [[ $PLAYER_SIGN = 'X' ]]
        then echo 'O'
        else echo 'X'
    fi
}

make_move() {
    is_row_correct=false
    is_col_correct=false

    echo

    read -re -p 'Введите координаты хода в формате "Строка Столбец": ' row col

    for valid_num in 0 1 2; do
        if [[ $row = $valid_num ]]; then
            is_row_correct=true
        fi
        if [[ $col = $valid_num ]]; then
            is_col_correct=true
        fi
    done

    if [[ $is_row_correct = false ]] || [[ $is_col_correct = false ]]; then
        echo 'Неверный формат ввода, повторите попытку'
        return
    fi

    state_pos=$((3 * $row + $col))
    if [[ ${GAME_STATE:state_pos:1} != ' ' ]]; then
        echo 'Данная клетка уже занята!'
        return
    fi

    NEED_TO_REPAINT=true

    insert_sign_into_desk $PLAYER_SIGN $row $col
    echo $row $col > game_pipe
    TURN_OF=`get_enemy_sign`
}

wait_enemy_move() {
    move=`cat game_pipe`
    if [[ $move != '' ]]; then
        NEED_TO_REPAINT=true
        insert_sign_into_desk `get_enemy_sign` $move
        TURN_OF=$PLAYER_SIGN
    fi
}

check_endof_game() {
    d_w=`check_diagonals_winner`
    v_w=`check_verticals`
    h_w=`check_horizontals`

    for winner in $d_w $v_w $h_w; do
        check_result $winner
    done

    no_space=true
    if echo "${GAME_STATE}" | grep -q ' '; then no_space=false; fi
    if [[ $no_space = true ]]; then
        repaint_game_desk
        echo 'Draw!'
        sleep 3
        exit
    fi
}

check_result() {
    if [[ $1 != '' ]]; then
        repaint_game_desk
        if [[ $1 = $PLAYER_SIGN ]]
            then echo 'You win!'
            else echo 'You lose!'
        fi
        sleep 3
        exit
    fi
}

check_diagonals_winner() {
    possible_winner=${GAME_STATE:4:1}
    if [[ $possible_winner = ' ' ]]; then return
    fi

    if [[ ${GAME_STATE:0:1} = $possible_winner ]] && [[ ${GAME_STATE:8:1} = $possible_winner ]]; then
        echo $possible_winner
        return
    fi

    if [[ ${GAME_STATE:2:1} = $possible_winner ]] && [[ ${GAME_STATE:6:1} = $possible_winner ]]; then
        echo $possible_winner
    fi
}

check_verticals() {
    for col in 0 1 2; do
        sym=${GAME_STATE:col:1}
        for row in 1 2; do
            curr=${GAME_STATE:3 * row + col:1}
            if [[ $curr != $sym ]]; then break; fi
            if [[ $row = 2 ]]; then
                echo $sym
                return
            fi
            sym=$curr
        done
    done
}

check_horizontals() {
    for row in 0 1 2; do
        sym=${GAME_STATE:3 * row:1}
        for col in 1 2; do
            curr=${GAME_STATE:3 * row + col:1}
            if [[ $curr != $sym ]]; then break; fi
            if [[ $col = 2 ]]; then
                echo $sym
                return
            fi
            sym=$curr
        done
    done
}

repaint_game_desk() {
    tput reset
        
    echo 'Вы играете за '$PLAYER_SIGN
    echo 'Делает ход игрок '$TURN_OF
    echo '    0   1   2'
    echo '  ┏━━━┳━━━┳━━━┓'
    for i in 0 1 2; do
        for j in 0 1 2; do
            m=${GAME_STATE:3 * i + j:1}
            if [[ $j = 0 ]]
                then echo -n ${i}' ┃ '${m}' '
                else echo -n '┃ '${m}' '
            fi
        done

        echo '┃ '

        if [[ $i != 2 ]];
            then echo '  ┣━━━╋━━━╋━━━┫'
            else echo '  ┗━━━┻━━━┻━━━┛'
        fi
    done
}

insert_sign_into_desk() {
    state_pos="3 * $2 + $3"
    GAME_STATE=${GAME_STATE:0:state_pos}$1${GAME_STATE:state_pos + 1}
}

run_game

var fs              = require('fs');
var ircC            = require('irc-colors');
var moment          = require('moment');
var _               = require('underscore');
var EventEmitter    = require('events').EventEmitter;
var util            = require('util');

/* */

var Quiz = module.exports = function (opts) {
    this.quizdata           = JSON.parse(this.quizdata = fs.readFileSync(__dirname + '/quizdata.json', {encoding: 'utf8'}));
    this.debug              = opts.debug;
    this.database           = opts.database;
    this.connectionId       = opts.connectionId;

    this.rules              = ['No excessive flooding and scripting','It\'s a privilege, not a right to quiz.'];
    this.running            = false;
    this.halted             = false;
    this.questioncounter    = 1;
    this.question           = false;
    this.lang               = '';
    this.channel            = null;
    this.questiontime       = null;

    this.waitDelay          = 5 * 1000;
    this.waitTimer          = null;

    this.hintDelay          = 30 * 1000;
    this.hintTimer          = null;
    this.hintcount          = 0;
    this.MAX_HINTS          = 5;

    this.haltDelay          = 5 * 60 * 1000;
    this.haltTimer          = null;
};
util.inherits(Quiz, EventEmitter);
Quiz.prototype.isChannel = function (channelName) {
    return this.channel !== null && channelName === this.channel.getName();
};
Quiz.prototype.getQuestionTime = function () {
    return this.questiontime;
};
Quiz.prototype.getQuestion = function () {
    return this.question;
};
Quiz.prototype.getCounter = function () {
    return this.questioncounter;
};
Quiz.prototype.isRunning = function () {
    return this.running;
};
Quiz.prototype.isHalted = function () {
    return this.halted;
};
Quiz.prototype.getScore = function (nick) {
    return parseInt(this.database[this.connectionId][nick] || 0, 10);
};
Quiz.prototype.setScore = function (nick, score) {
    this.database[this.connectionId][nick] = score;
    this.database.save();
};
Quiz.prototype.addScore = function (nick, score) {
    var _score = this.getScore(nick),
        newScore = _score + score;
    this.setScore(nick, newScore);
    this.database.save();
    return newScore;
};
Quiz.prototype.getToplist = function () {
    this.debug(this.database);
    var scores = _.map(this.database[this.connectionId], function (score, nick) {
        return {
            'nick': nick,
            'score': score
        };
    });
    scores.sort(function (a, b) {
        return b.score - a.score;
    });
    return scores;
};
Quiz.prototype.getRank = function (nick) {
    var scores = this.getToplist(), i;
    for (i = 0; i < scores.length; i += 1) {
        if (scores[i].nick === nick) {
            return i + 1;
        }
    }
    return scores.length + 1;
};
Quiz.prototype.start = function (lang, channel) {
    this.debug(lang);
    this.lang               = lang;
    this.debug(this.lang);
    this.channel            = channel;
    this.running            = true;
    this.halted             = false;
    this.questioncounter    = 0;
};
Quiz.prototype.getNewQuestion = function () {
    this.question = _.sample(this.quizdata[this.lang].entries);
    while (this.question.solved === true) {
        this.question = _.sample(this.quizdata[this.lang].entries);
    }
    this.question.solved = false;
    this.questiontime = moment();
    this.questioncounter += 1;
    this.hintcount = 0;

    this.debug('%j', this.question);

    this.channel.say('[%s] La question N. %s est: %s', ircC.bold('QUIZ'), ircC.bold(this.questioncounter), this.getQuestionString());
    //this.channel.say('[%s] %s', ircC.bold('QUIZ'), this.getQuestionString());
    this.startHints();
};
Quiz.prototype.getTotalQuestionCount = function () {
    this.debug(this.lang);
    return this.quizdata[this.lang].questions;
};
Quiz.prototype.getQuizdataCreationDate = function () {
    return moment(this.quizdata[this.lang].created).format('dddd, MMMM Do YYYY, HH:mm:ss');
};
Quiz.prototype.getQuestionString = function () {
    var str = '';
    if (this.question.hasOwnProperty('category')) {
        str = '(' + this.question.category + ') ';
    }
    str += this.question.question;
    return str;
};
Quiz.prototype.stop = function () {
    this.lang = '';
    this.channel = null;
    this.running = false;
    this.questioncounter = 0;
    if (this.waitTimer) {
        clearTimeout(this.waitTimer);
    }
    if (this.hintTimer) {
        clearTimeout(this.hintTimer);
    }
    if (this.haltTimer) {
        clearTimeout(this.haltTimer);
    }
};
Quiz.prototype.unhalt = function () {
    this.halted = false;
    this.resetHaltTimer();
    this.startHints();
};
Quiz.prototype.halt = function () {
    this.halted = true;
    if (this.waitTimer) {
        clearTimeout(this.waitTimer);
    }
    if (this.hintTimer) {
        clearTimeout(this.hintTimer);
    }
    if (this.haltTimer) {
        clearTimeout(this.haltTimer);
    }
};
Quiz.prototype.isRight = function (text) {
    if (this.question === null) {
        return false;
    }
    text = text.toLowerCase();
    if (this.question.solved || !this.question) {
        return false;
    }
    if (this.question.hasOwnProperty('regexp')) {
        if (text.match(new RegExp(this.question.regexp, 'i'))) {
            this.debug('regexp: %s', this.question.regexp);
            return true;
        }
    } else {
        var answer, tr;
        answer = this.question.answer.replace(/\#/g, '').toLowerCase();
        answer = answer.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&');
        tr = {
            'ä': 'ae',
            'ü': 'ue',
            'ö': 'oe',
            'é': 'e',
            'è': 'e',
            'à': 'a',
            'ß': 'ss'
        };
        if (text.search(answer) !== -1) {
            this.debug('search: %s', answer);
            return true;
        }
        text = text.replace(/[äöüß]/g, function ($0) {
            return tr[$0];
        });
        answer = answer.replace(/[äöüß]/g, function ($0) {
            return tr[$0];
        });

        if (text.search(answer) !== -1) {
            this.debug('replace: %s', answer);
            return true;
        }
    }
    return false;
};
Quiz.prototype.startHints = function () {
    if (this.hintTimer) {
        clearTimeout(this.hintTimer);
    }
    var self = this;
    this.hintTimer = setTimeout(function () {
        self.getHint();
    }, this.hintDelay);
};
Quiz.prototype.getAnswer = function () {
    return this.question.answer.replace(/\#/g, '');
};
Quiz.prototype.getHint = function () {
    var self = this,
        time,
        hint,
        parts,
        part,
        p,
        j;
    self.hintcount += 1;
    this.debug('getHint -> %s | %s', self.hintcount, self.MAX_HINTS);
    if (self.hintcount > self.MAX_HINTS) { //MAX_HINTS
        self.question.solved = true;
        time = moment.duration(self.getQuestionTime().diff(moment()), 'milliseconds').humanize();
        self.channel.say('[%s] Repondu automatiquement apres %s.', ircC.bold('QUIZ'), time);
        self.channel.say('[%s] La reponse est: %s', ircC.bold('QUIZ'), ircC.bold(self.getAnswer()));
        self.delayNewQuestion();
    } else {
        hint = '';
        parts = self.question.answer.replace(/\#/g, '').match(new RegExp('.{1,' + self.MAX_HINTS + '}', 'g'));
        for (p = 0; p < parts.length; p += 1) {
            part = parts[p];
            for (j = 0; j < part.length; j += 1) {
                if (j + 1 <= self.hintcount) {
                    hint += part.charAt(j);
                } else {
                    if (part.charAt(j) === ' ') {
                        hint += ' ';
                    } else {
                        hint += '_';
                    }
                }
                hint += ' ';
            }
        }
        self.channel.say('[%s] Indice: %s', ircC.bold('QUIZ'), ircC.bold(hint));
        self.hintTimer = setTimeout(function () {
            self.getHint();
        }, self.hintDelay);
    }
};
Quiz.prototype.delayNewQuestion = function (time) {
    time = _.isUndefined(time) ? this.waitDelay : time;
    if (this.hintTimer) {
        clearTimeout(this.hintTimer);
    }
    this.waitTimer = setTimeout(this.getNewQuestion.bind(this), time);
};
Quiz.prototype.resetHaltTimer = function () {
    if (this.haltTimer) {
        clearTimeout(this.haltTimer);
    }
    var self = this;
    this.haltTimer = setTimeout(function () {
        self.halt();
        self.channel.say('[%s] Quiz interrompu. Demandez "!ask" pour des nouvelles questions.', ircC.bold('QUIZ'));
    }, this.haltDelay);
};









/* */

module.exports = function (scriptLoader) {
    var database = scriptLoader.database('quiz');
    database[scriptLoader.connection.getId()] = database[scriptLoader.connection.getId()] || {};
    database.save();
    var quiz = new Quiz({
        debug: scriptLoader.debug,
        database: scriptLoader.database('quiz'),
        connectionId: scriptLoader.connection.getId()
    });

    scriptLoader.on('command', 'quiz', function (event) {
	console.log(event);
	console.log(event.user);
        if (!event.channel.userHasMinMode(event.user, '%')) {
            return event.user.notice('PAS LE DROIT');
        }
        if (event.params.length === 0) {
            return event.user.notice('Use: !quiz <START|STOP|HALT|NEXT> [...]');
        }
        if (event.params[0].toUpperCase() === 'START') {
            if (quiz.isRunning()) {
                return event.user.notice('Die Quizrunde läuft bereits.');
            }
            var lang = event.params.length > 1 ? event.params[1] : 'fr';
            if (!_.has(quiz.quizdata, lang)) {
                return event.user.notice('Ich habe keine Fragen in dieser Sprache.');
            }
            quiz.start(lang, event.channel);
            event.channel.say('[%s] %s demande du quiz, et bah il va en avoir: %s questions disponibles "%s" (%s).',
                ircC.bold('QUIZ'),
                ircC.underline(event.user.getNick()),
                ircC.bold(quiz.getTotalQuestionCount()),
                lang,
                quiz.getQuizdataCreationDate());
            quiz.delayNewQuestion(0);
            quiz.resetHaltTimer();
            return;
        } else if (event.params[0].toUpperCase() === 'STOP') {
            if (!quiz.isRunning()) {
                return event.user.notice('Es läuft aktuell keine Quizrunde.');
            }
            quiz.stop();
            event.channel.say('[%s] Fin du quiz.', ircC.bold('QUIZ'));
        } else if (event.params[0].toUpperCase() === 'HALT') {
            if (!quiz.isRunning()) {
                return event.user.notice('Es läuft aktuell keine Quizrunde.');
            }
            if (quiz.isHalted()) {
                return event.user.notice('Die aktuelle Quizrunde wurde bereits angehalten.');
            }
            quiz.halt();
            event.channel.say('[%s] Quiz en pause, demandez "!ask" pour continuer.', ircC.bold('QUIZ'));
        } else if (event.params[0].toUpperCase() === 'NEXT') {
            if (!quiz.isRunning()) {
                return event.user.notice('Es läuft aktuell keine Quizrunde.');
            }
            var question = quiz.getQuestion();
            question.solved = true;
            event.channel.say('[%s] Resolution manuelle en %s par %s.',
                ircC.bold('QUIZ'),
                moment.duration(quiz.getQuestionTime().diff(moment()), 'milliseconds').humanize(),
                event.user.getNick());
            event.channel.say('[%s] La reponse etait: %s',
                ircC.bold('QUIZ'),
                quiz.getAnswer());
            quiz.delayNewQuestion();
        }
    });
    scriptLoader.on('command', 'ask', function (event) {
        if (!quiz.isRunning()) {
            return event.user.notice('QUIZ est eteint');
        }
        if (!quiz.isChannel(event.channel.getName())) {
            return event.user.notice('Ca marche que sur le channel ' + quiz.channel.getName() + '.');
        }
        if (quiz.isHalted()) {
            quiz.unhalt();
        }
        event.channel.say('[%s] La question Nr. %s est:', ircC.bold('QUIZ'), ircC.bold(quiz.getCounter()));
        event.channel.say('[%s] %s', ircC.bold('QUIZ'), quiz.getQuestionString());
    });
    scriptLoader.on('command', 'rules', function (event) {
        if (!quiz.isRunning()) {
            return event.user.notice('Le quiz est eteint');
        }
        if (!quiz.isChannel(event.channel.getName())) {
            return event.user.notice('Le quiz ne fonctionne que sur %s.', quiz.channel.getName());
        }
        _.each(quiz.rules, function (rule) {
            event.user.notice(rule);
        });
    });
    scriptLoader.on('command', 'quizrank', function (event) {
        var scores = quiz.getToplist(),
            userscore = {
                'nick': event.user.getNick(),
                'score': -1,
                'index': -1
            },
            index;
        for (index = 0; index < scores.length; index += 1) {
            if (index < 5) {
                userscore.score = 0;
                event.user.notice('[%s] %s - %spt',
                    index + 1,
                    scores[index].nick === event.user.getNick() ? ircC.bold(scores[index].nick) : scores[index].nick,
                    scores[index].score
                );
            } else {
                if (scores[index].nick === event.user.getNick()) {
                    userscore.score = scores[index].score;
                    userscore.index = index + 1;
                }
            }
        }
        if (userscore.score !== 0) {
            if (scores.length > 5 && userscore.index !== 6) {
                event.user.notice('...');
            }
            event.user.notice('[%s] %s - %spt',
                userscore.score === -1 ? (scores.length + 1) : userscore.index,
                ircC.bold(userscore.nick),
                userscore.score
            );
        }
    });
    scriptLoader.on('command', 'setscore', function (event) {
        if (!event.user.isAdmin()) {
            return event.user.notice('PAS LE DROIT !');
        }
        if (event.params.length === 0) {
            return event.user.notice('Verwendung: !setscore [nick] <score>');
        }
        var nick, score;
        if (event.params.length === 1) {
            nick = event.user.getNick();
            score = parseInt(event.params[0], 10);
            if (isNaN(score)) {
                return event.user.notice('score war NaN.');
            }
        } else if (event.params.length === 2) {
            nick = event.params[0];
            score = parseInt(event.params[1], 10);
            if (isNaN(score)) {
                return event.user.notice('score war NaN.');
            }
        }
        quiz.setScore(nick, score);
        event.channel.say('%s a maintenant <%s> points.',
            nick,
            score
        );
    });
    scriptLoader.on('message', function (event) {
        if (quiz.isRunning() && !quiz.isHalted() && quiz.isChannel(event.channel.getName())) {
            if (quiz.isRight(event.message)) {
                var question = quiz.getQuestion(),
                    nick = event.user.getNick(),
                    time = moment.duration(quiz.getQuestionTime().diff(moment()), 'milliseconds').humanize(),
                    points = question.score || 1,
                    score = quiz.addScore(nick, points),
                    rank = quiz.getRank(nick);
                question.solved = true;
                event.channel.say('[%s] %s a repondu a la question en %s <%s> (+%s) classement %s. La reponse etait: %s',
                    ircC.bold('QUIZ'),
                    ircC.bold(nick),
                    ircC.bold(time),
                    ircC.bold(score),
                    ircC.bold(points),
                    ircC.bold(rank),
                    ircC.bold(quiz.getAnswer())
                );
                quiz.delayNewQuestion();
            }
            quiz.resetHaltTimer();
        }
    });
};

class LinebotvnController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'

  # callbackvnアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callbackvn]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callbackvn
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)

    #ここでlineに送られたイベントを検出している
    # messageのtext: に指定すると、返信する文字を決定することができる
    #event.message['text']で送られたメッセージを取得することができる
    events.each { |event|
      auth = ENV["NANONET_BASIC_AUTH_VIETNHAT"]
      modelId = ENV["NANONET_MODEL_ID_VIETNHAT"]

      urls = event.message['text'] #ここでLINEで送った文章を取得
      result = `curl --user #{auth} -X POST https://app.nanonets.com/api/v2/ImageCategorization/LabelUrls/?modelId=#{modelId}'&'urls=#{urls}`
      #ここでNanonet APIを叩く
      hash_result = JSON.parse result #レスポンスが文字列なのでhashにパースする
      results = hash_result["result"] #ここで結果情報が入った入れつとなる
      result = results.sample #任意のものを一個選ぶ
      predictions = result["prediction"]
      prediction = predictions.sample

      puts prediction
      #ラベルの情報
      label = prediction["label"] #ラベルを送る
      probability = prediction["probability"] #確率を送る

      if probability > 0.5
        if probability < 0.9
          comment = "かなり" + label + "の人ですね～"
        else
          comment = "ほとんど" + label + "の人ですね～"
        end
      else
        if probability < 0.1
          comment = "ほとんど" + label + "の人ではないですね～"
        else
          comment = "あまり" + label + "の人ではないですね～"
        end
      end    
      response = comment + "\n" + "\n" + "【人判定】" + label + "\n" + "【確率】" + probability.to_s

      case event #case文　caseの値がwhenと一致する時にwhenの中の文章が実行される(switch文みたいなもの)
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message1 = {
            type: 'sticker',
            packageId: 1,
            stickerId: 1
          }

          message2 = {
            type: 'text',
            text: response
          }
 
          message3 = {
            type: 'image',
            originalContentUrl: urls,
            previewImageUrl: urls
          }
          
          client.reply_message(event['replyToken'], [message1, message2, message3])

        end

      end
    }

    head :ok
  end
end


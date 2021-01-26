from flask import Flask
from flask_restful import Resource, Api

app = Flask(__name__)
api = Api(app)

class Product(Resource):
	def get (self):
		return  {
			'product': ['deal-core',
						'deal-core2',
						'deal-core3']
		}
api.add_resource(Product, '/')

fi __name__ == "__main__": 
	app.run(host='0.0.0.0', port=80, debug=True)

